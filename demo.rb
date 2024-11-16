$LOAD_PATH.unshift 'lib'

require 'not_a_pipe'

extend NotAPipe

not_a_pipe def test
  'test' >> _.upcase >> puts
end

test
# prints "TEST"

require 'open-uri'
require 'json'

not_a_pipe def repos(username)
  username >>
    ("https://api.github.com/users/%s/repos" % _) >>
    URI.open >>
    _.read >>
    JSON.parse(symbolize_names: true) >>
    _.map { _1.dig(:full_name) }.first(10) >>
    pp
end

repos('zverok')
# prints: ["zverok/any_good", "zverok/awesome-codebases", "zverok/awesome-events", "zverok/backports", ...
