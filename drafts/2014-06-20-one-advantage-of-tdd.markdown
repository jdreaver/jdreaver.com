---
title: TDD as Empirical Evidence of Test Effectiveness
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
TDD can be great when you feel it is appropriate. Of course, deciding when to
use it is a matter of taste and experience. This post won't advocate for TDD
all the time, but it will highlight one advantage of TDD: **you know your tests
are testing what they are supposed to test.**

Consider the fact that we write tests to help verify the correctness of our
code. We know that even though we write tests, there are still bugs lurking,
waiting to reveal themselves when we least expect them to. Also be aware that
some of those bugs may lie in our testing code. How, then, do we verify our
tests? That is, how do we **know** our tests are actually testing our code? Is
it turtles all the way down; tests on tests on tests?

In this article, I am going to discuss the class of bugs that lie in tests, and
result in a *passing* test when the test should fail. I argue that **it is
important to see a test fail, and then pass when the correct code is written**.
I arrived when something like the following example happened to me.

## Turtles all the way down...

How do we ensure tests are correct? Let's assume that we cannot be 100% free of
bugs. That is, given enough time, our software will act erroneously. We don't
write tests with the expectation that every bug will be caught. Instead, **we
write tests to decrease the probability of a bug occurring.** Passing tests,
then, can be considered *empirical evidence* that our code works as intended.

When we consider how to verify our tests are correct, we can't just write more
tests. At that point, it's turtles all the way down; we end up at square one.
Instead, we can shoot for the less-lofty goal of *supporting* the evidence that
our test works as intended. Like I proposed earlier, seeing a test fail, then
pass after the code has changed provides strong evidence that the test works as
intended.


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


## Relationship between the fail/pass cycle and tests

I think it would be great if a testing framework could integrate with version
control like this:

* Write a failing test and create a commit.
* Write the new code or bug fix that makes the test pass, and commit.
* In the future, we can run our tests in this version control mode.
