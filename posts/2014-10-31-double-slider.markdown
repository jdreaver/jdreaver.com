---
title: Creating a DoubleSlider in PySide/PyQt
---

In this article I will explain how I modified the Qt `QSlider` class to handle
doubles. If you just want to see the (fairly simple) code, see
[this gist](https://gist.github.com/jdreaver/88a4f82666d60e72f45a).

## Motivation

At work, I created a GUI to run a scientific simulation. The simulation
produces data as a function of time, and the GUI can plot that data at any
specified time. I was using a `QSlider` to allow the user to control the plot
time. This worked great for large time scales; I could set the maximum value of
the slider to the current maximum plot time, and moving the slider would
directly produce the desired plot time.

However, this does not work for smaller time scales. One user ran a simulation
that had a time scale on the order of microseconds. Since `QSlider` operates on
integers, he couldn't plot his data because the slider value was either zero or
one! Therefore, I needed a way for the slider to keep track of arbitrary ranges
of time using doubles.


## Implementation

We will need to subclass `QSlider` to keep track of the minimum and maximum
values, and the current value, all in doubles. We will do this using private
properties, and mapping the current range in doubles to a static integer range
for the parent class.

One might be tempted to look at the
[documentation for QSlider](http://pyside.github.io/docs/pyside/PySide/QtGui/QSlider.html)
to evaluate what functions need to be subclassed, but in fact most of the
desired functions are in the
[documentation for QAbstractSlider](http://pyside.github.io/docs/pyside/PySide/QtGui/QAbstractSlider.html).

Let's start with the `__init__` function:

```python
class DoubleSlider(QtGui.QSlider):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # Set integer max and min on parent. These stay constant.
        super().setMinimum(0)
        self._max_int = 10000
        super().setMaximum(self._max_int)

        # The "actual" min and max values seen by user.
        self._min_value = 0.0
        self._max_value = 100.0
```

First, we set a reasonable resolution for the slider at 10,000 ticks. This
number won't change; we will change `_min_value` and `_max_value` and convert
the slider position to a value relative to those two values:

```python
    @property
    def _value_range(self):
        return self._max_value - self._min_value

    def value(self):
        return float(super().value()) / self._max_int * self._value_range

    def setValue(self, value):
        super().setValue(int(value / self._value_range * self._max_int))
```

This code is fairly simple. We are just converting the tick position (between 0
and 10,000) to and from a value based on our range (from `_value_range`).

Finally, the user can set the minimum and maximum values of the slider using
the normal `setMinumum`, `setMaximum`, and `setRange` functions. We secretly
assign the min and max values to our private properties:

```python
    def setMinimum(self, value):
        self.setRange(value, self._max_value)

    def setMaximum(self, value):
        self.setRange(self._min_value, value)

    def setRange(self, minimum, maximum):
        old_value = self.value()
        self._min_value = minimum
        self._max_value = maximum
        self.setValue(old_value)  # Put slider in correct position
```

Notice that we end `setRange` with `self.setValue(old_value)`. We do this to
position the slider tick correctly within the new range. For example, if the
old range was 0 to 1, and the value is 0.5, then the slider tick will by
half-way in between the endpoints. However, if we change the maximum to 2, then
the slider tick needs to by one quarter of the slider length away from the left
side.

For a cherry on top, I created a convenience function to find the current
proportion of the slider value relative to the value range:

```python
    def proportion(self):
        return (self.value() - self._min_value) / self._value_range
```

## Conclusion

We have created a `QSlider` subclass that can handle doubles instead of using
just integers. For all of the code, see
[this gist](https://gist.github.com/jdreaver/88a4f82666d60e72f45a).

Thanks for reading!
