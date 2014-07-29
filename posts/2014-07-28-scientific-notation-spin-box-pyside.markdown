---
title: A Scientific Notation Double Spin Box for PyQt/PySide
---

In this post I am going to describe how I built a modified `QDoubleSpinBox`
that can handle scientific notation. If you just want the code, check out this
[gist](https://gist.github.com/jdreaver/0be2e44981159d0854f5).

## Motivation

The GUI I a creating at work requires a lot of individual float inputs. Before
today, I was using a modified `QLineEdit` subclass that called the Python
`float()` builtin to convert the text to a value. The problem with this
approach is it is hard to come up with sensible behavior when the text is not a
valid float. I needed behavior like that of a `QDoubleSpinBox`, but I needed to
work with numbers in scientific notation. By default, a `QDoubleSpinBox` cannot
handle scientific notation, so I had to roll my own `ScientificDoubleSpinBox`.

I'll explain the process in the next sections:

1. Create a `QValidator` to check if floats are valid.
2. Subclass `QDoubleSpinBox` to plug in this validator.


## Detecting valid floats

The python `float()` function can handle scientific notation in a few various
forms:

```python
>>> float("1.2e4")
12000.0
>>> float("1.2e+04")
12000.0
>>> float("1.2e-4")
0.00012
```

To validate a float, we could simply wrap the `float()` function in a
`try/except` block. However, we will need to use various parts of the float
string later on, so let's create a regular expression and a function to
validate a float string:

```python
# Regular expression to find floats. Match groups are the whole string, the
# whole coefficient, the decimal part of the coefficient, and the exponent
# part.
_float_re = re.compile(r'(([+-]?\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)')

def valid_float_string(string):
    match = _float_re.search(string)
    return match.groups()[0] == string if match else False
```

Here are some examples of using the regular expression and the function:

```python
>>> _float_re.search("-10.23e-5").groups()
('-10.23e-5', '-10.23', '.23', 'e-5')
>>> valid_float_string("1.3e4")
True
>>> misc.valid_float_string("abcdefg")
False
```


## Scientific notation QValidator

A `QValidator` is installed on into widgets such as `QLineEdit` to detect in
real time if the value being entered is valid. For example, our validator
should allow a user to enter any value that can be interpreted as a float.
While editing, a user should not be able to enter a value that cannot possibly
be in a scientific notation string (every character in `_float_re`).

```python
class FloatValidator(QtGui.QValidator):

    def validate(self, string, position):
        if valid_float_string(string):
            return self.State.Acceptable
        if string == "" or string[position-1] in 'e.-+':
            return self.State.Intermediate
        return self.State.Invalid

    def fixup(self, text):
        match = _float_re.search(text)
        return match.groups()[0] if match else ""
```

The `validate` method is called by the editing widget to determine if the
entered value is alright, intermediate (not alright, but not quite invalid), or
invalid. The `fixup` method attempts to fix the string. Our `fixup` method
searches for a valid float string inside the entire text, and returns that.

We could use this validator on a line edit with
`QLineEdit.setValidator(validator)`, but we want some of the features of a
QDoubleSpinBox, like increment/decrement buttons, and automatic float
conversion. We don't actually use the validator as a `QValidator`, but is nice
to have in case you want to use it for something similar.


## QDoubleSpinBox subclass

Now, we just combine the plumbing we just built into a subclass of
`QDoubleSpinBox`:

```python
class ScientificDoubleSpinBox(QtGui.QDoubleSpinBox):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.setMinimum(-np.inf)
        self.setMaximum(np.inf)
        self.validator = FloatValidator()
        self.setDecimals(1000)

    def validate(self, text, position):
        return self.validator.validate(text, position)

    def fixup(self, text):
        return self.validator.fixup(text)

    def valueFromText(self, text):
        return float(text)

    def textFromValue(self, value):
        return format_float(value)

    def stepBy(self, steps):
        text = self.cleanText()
        groups = _float_re.search(text).groups()
        decimal = float(groups[1])
        decimal += steps
        new_string = "{:g}".format(decimal) + (groups[3] if groups[3] else "")
        self.lineEdit().setText(new_string)


def format_float(value):
    """Modified form of the 'g' format specifier."""
    string = "{:g}".format(value).replace("e+", "e")
    string = re.sub("e(-?)0*(\d+)", r"e\1\2", string)
    return string
```

All of the methods except for `stepBy` are self explanatory. The `stepBy`
method is used when the step buttons are pressed. In our implementation, we use
our regular expression groups to extract the coefficient of the scientific
notation string, and increment it. The `format_float` function is just a nicer
version of `"{:g}".format(value)`.


## Conclusion

We created a `QDoubleSpinBox` subclass that can handle scientific notation. We
also created a `QValidator` that, while not used in the spin box, is useful to
validate float strings. Check out this
[gist](https://gist.github.com/jdreaver/0be2e44981159d0854f5) for all of the
code.
