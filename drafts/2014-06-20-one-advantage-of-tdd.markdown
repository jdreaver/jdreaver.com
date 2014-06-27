---
title: Are your tests correct? One advantage of Test-Driven Development
---

In case you haven't heard of
[Test-Driven Development](http://en.wikipedia.org/wiki/Test-driven_development)
(TDD), it is a development practice in which the developer follows the
following three steps when writing code:

1. Decide to write a new feature or piece of code.
2. Write a test that will verify the new code works. Of course, this test
   should fail for now.
3. Write code until the test passes.
4. Repeat.

Like any decent development methodology, some programmers find out about TDD
and quickly proclaim it to be the One True Way™ to write code. In my opinion,
TDD can be great when you feel like using it, and when it is appropriate. Of
course, deciding when to use it is a matter of taste and experience. This post
won't advocate for TDD all the time, but it will highlight one advantage of
TDD: **you know your tests are testing what they are supposed to test.**

Consider the fact that we write tests to verify the correctness of part of our
code. How do we verify our tests? That is, how do we **know** our tests are
actually testing our code? Is it turtles all the way down; tests on tests on
tests?

I argue that **it is important to see a test fail, and then pass when the
correct code is written**. I arrived when something like the following example
happened to me.

## Example

In my current job, I write software that happens to deal with *a lot* of units.
I have to convert between any arbitrary units the user decides to enter when
they give us data (have you ever encountered BTU/hr/ft/F, or the oil industry's
made-up units like ppa? Me neither until now, and I have a mechanical
engineering degree). Naturally, I needed a way to check if the user entered
valid units for a quantity, before I go try to convert it later on. I decided
to use TDD, and I wrote the following tests:

```python
def test_check_unit_validity():
    assert check_unit_validity("ft", "length")
    assert not check_unit_validity("s", "length")
    assert not check_unit_validity("", "length")
    assert not check_unit_validity("", "angle")
    assert check_unit_validity("deg", "angle")
```

As you can see, the first argument is the units as a string, and the second
argument is the type of unit. As a sidenote, I use the
[Pint](https://github.com/hgrecco/pint) library for Python to convert units,
and I have unit types defined in a config file; this is unimportant for now.


```python
def check_unit_validity(units, unit_type):
    """Checks that units are valid for unit_type.

    Args:
      units (str): units to be validated
      unit_type (str): type of units

    Returns:
      bool: True if units are of unit_type, False otherwise

    """
    # Code to check units goes here
```
