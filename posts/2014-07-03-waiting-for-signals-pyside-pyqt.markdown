---
title: Waiting for Signals in PySide and PyQt
---

Recently, I was writing an integration test for a data visualization GUI. The
GUI calls out to an external process to run a simulation, waits for the
simulator to produce data, and reads the data back in to produce pretty graphs,
export data to other formats, etc. I use a PySide signal to inform the GUI that
the simulator has produced data. Unfortunately, I couldn't find a clean way to
have my integration test wait for that signal. Luckily, I have found the
solution, and I'll explain it here.

## Signals and Slots

PySide and PyQt are Python bindings to the [Qt](http://qt-project.org/) GUI and
application framework. One killer feature of Qt is the
[signal & slot](http://qt-project.org/doc/qt-4.8/signalsandslots.html) system,
which is a way for widgets and objects to communicate events to one another.

An object in Qt can send a *signal* to other subscribed objects. Signals are
used to inform other objects that an event has occurred. For example, buttons
fire the `QPushButton.pressed` signal when they are clicked. When you want to
handle a button click, you *connect* the signal to a function. You can create
your own signals, and connect them to arbitrary python functions. In my GUI, I
have something like the following:

```python
class GUI:

    def __init__(self):
        self.simulator = Simulator()
        self.data_reader = DataReader()
        self.simulator.finished.connect(self.data_reader.read_data)

        self.startButton = QtGui.QPushButton("Start")
        self.startButton.pressed.connect(self.simulator.run_simulation)

class Simulator(QtCore.QObject):

    """Controls simulation and emits a ``finished`` signal when done."""

    finished = QtCore.Signal()

    def run_simulation(self):
        """Run the simulator in an external process."""
        self.process = QtCore.QProcess()
        self.process.finished.connect(self.finished)
        self.process.start(simulator_exe)
    ...

class DataReader:

    """Reads data files from simulator."""

    def read_data(self):
        load_files()
    ...
```

In this code snippet, we create the ``Simulator`` and ``DataReader`` classes,
and connect them together using a signal. The ``Simulator`` class is a
``QObject``, so it can send signals. It runs a simulation in a separate
process, and then emits the ``finished`` signal when it's done. We also happen
to use a button that starts the simulation when clicked. We connect the
simulator's ``finished`` signal to the ``DataReader`` so it knows when to begin
reading data.


## The Test

So, how do I test the above code? I want to run the simulator and make sure it
has the correct output. I initially wrote a test like this:

```python
def test_simulator_output():
    simulator = Simulator()
    simulator.run_simulation()

    assert_correct_output(simulator)
```

What's wrong here? The assertion line is executed too early; the simulator
probably hasn't even started in the nanoseconds between when I told it to start
and when I check the data! How can we solve this issue? I tried a
``time.sleep()`` loop that polls if the simulation is complete. This blocks the
main GUI thread, and is not a good solution. I also tried similar things using
the ``threading`` module, but to no avail. It turns out, we can use a new Qt
event loop to stop execution.

## Solution

I figured out that you can call ``QEventLoop.exec_()`` to create a nested event
loop. That is, our QApplication instance event loop is already running, but
calling ``QEventLoop.exec_()`` will stop execution using a new event loop until
``QEventLoop.quit()`` is called. Here is our modified example test:

```python
def test_simulator_output():
    simulator = Simulator()

    loop = QtCore.QEventLoop()
    simulator.finished.connect(loop.quit)
    simulator.run_simulation()
    loop.exec_()  # Execution stops here until finished called

    assert_correct_output(simulator)
```

We create an event loop that will help us wait for our simulation to complete.
When ``run_simulation()`` is called, we wait at the ``loop.exec_()`` line until
``finished`` is emitted. When the simulator finishes, the event loop will exit,
and we will advance beyond the ``loop.exec_()`` line.

## General Solution

There is one problem with this approach. What if ``simulator.finished`` is
never emitted, like when an error occurs? We would never advance beyond
``loop.exec_()``. If we had this test running on a continuous integration
server, we would lock up a job forever until we realized the test never
finished!

A solution is to use the ``QTimer.singleShot()`` function with a timeout. That
means for every time we want to create an event loop, we have to set up the
loop, hook up our signals, and create a timer with a suitable timeout in case
the signals never fire. Here is a context manager that can handle this for us:

```python
@contextmanager
def wait_signal(signal, timeout=10000):
    """Block loop until signal emitted, or timeout (ms) elapses."""
    loop = QtCore.QEventLoop()
    signal.connect(loop.quit)

    yield

    if timeout is not None:
        QtCore.QTimer.singleShot(timeout, loop.quit)
    loop.exec_()
```

We can use it like this:

```python
def test_simulator_output():
    simulator = Simulator()

    with wait_signal(simulator.finished, timeout=10000):
        simulator.run_simulation()

    assert_correct_output(simulator)
```

Isn't that great? I think so.

## pytest-qt

I run my tests using the [pytest](http://pytest.org/latest/) library. There is
a plugin for pytest called
[pytest-qt](https://github.com/nicoddemus/pytest-qt), which comes with a
fixture called ``qtbot``. A ``qtbot`` is used to handle all of the boilerplate that comes along with testing PySide/PyQt code, like:

* Setting up a QApplication
* Simulating mouse clicks and keyboard interaction
* Closing windows after tests

Once I figured out how to stop test execution to wait for a signal, I created a
[pull request](https://github.com/nicoddemus/pytest-qt/pull/13) to add this
functionality to pytest-qt. I created a more general solution that allows
multiple signals, or none at all (just wait for a timeout). If you use
PySide/PyQt, but you think testing your GUI code is a pain, check out
pytest-qt! Take a look at the
[example](https://pytest-qt.readthedocs.org/en/latest/#waiting-for-threads-processes-etc)
in the docs to see how to use pytest-qt to block tests for signals.

Thanks for reading!
