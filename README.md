<p align="center">
  <img src="https://raw.githubusercontent.com/zverok/not_a_pipe/master/img/une_pipe.jpg"/>
</p>

# This is not a pipe

This is an experimental/demo Ruby implementation of Elixir-style pipes. It allows to write code like this:

```ruby
require 'not_a_pipe'

extend NotAPipe

not_a_pipe def repos(username)
  username >>
    ("https://api.github.com/users/%s/repos" % _) >>
    URI.open >>
    _.read >>
    JSON.parse(symbolize_names: true) >>
    _.map { _1.dig(:full_name) }.first(10) >>
    pp
end
```

Basically:
* `not_a_pipe` is a decorator to mark methods inside which `>>` works as “pipe operator”;
* every step can reference `_` which would be a result of the previous step;
* but it also can omit the reference and just specify a method to call; the result of the previous step would be substituted as the _first argument_ of the method.

`not_a_pipe` works by _rewriting the AST_ and reevaluating the (rewritten) method code at the definition time and has no runtime penalty; thus achieving something akin to macros.

**It is not intended to use in production codebase**, but rather as an approach investigation/demonstration.

Inspired by a [Python’s library](https://github.com/Jordan-Kowal/pipe-operator?tab=readme-ov-file#-elixir-like-implementation) that uses the similar approach, and a [recent discussion](https://bugs.ruby-lang.org/issues/20770#note-34) in Ruby’s bug-tracker.

See also an [explanatory blog-post](TODO).

## Usage

Don’t. Really. The code is really naive, tested only for simple cases, and is not intended as a library that will be relied upon. It is an experiment.

But if you want to play, you can install it as a gem:

```bash
gem install not_a_pipe
```

...and then follow the example above.

## Benchmarks

See `benchmark.rb`. Compared versions are:
* “naive” Ruby code which puts values into intermediate variables;
* `.then`-based Ruby version that chains everything in one statement;
* `not_a_pipe` version
* [pipe_envy](https://github.com/hopsoft/pipe_envy)-based solution, which is pretty simple (allows to join callable objects with `>>`)
* [pipe_operator](https://github.com/LendingHome/pipe_operator)-based solution, which is impressively witty looking but requires an extensive implementation with “proxy objects”

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [x86_64-linux]
Warming up --------------------------------------
               naive     3.000 i/100ms
               .then     3.000 i/100ms
          not_a_pipe     4.000 i/100ms
       pipe_operator     1.000 i/100ms
           pipe_envy     1.000 i/100ms
Calculating -------------------------------------
               naive     18.488 (± 5.4%) i/s   (54.09 ms/i) -     93.000 in   5.067112s
               .then     15.622 (± 6.4%) i/s   (64.01 ms/i) -     78.000 in   5.019804s
          not_a_pipe     18.140 (± 5.5%) i/s   (55.13 ms/i) -     92.000 in   5.083882s
       pipe_operator      1.520 (± 0.0%) i/s  (657.81 ms/i) -      8.000 in   5.266537s
           pipe_envy      7.296 (±13.7%) i/s  (137.06 ms/i) -     37.000 in   5.098091s

Comparison:
               naive:       18.5 i/s
          not_a_pipe:       18.1 i/s - same-ish: difference falls within error
               .then:       15.6 i/s - 1.18x  slower
           pipe_envy:        7.3 i/s - 2.53x  slower
       pipe_operator:        1.5 i/s - 12.16x  slower
```

Note that `not_a_pipe` is the _fastest_ version, on par only with “naive” verbose Ruby code with intermediate variables, and without `.then`-chaining (truth be told, on various runs `.then`-based version is frequently “sam-ish”). The rewrite-on-load approach is a rare way to introduce a DSL without _any_ performance penalty.
