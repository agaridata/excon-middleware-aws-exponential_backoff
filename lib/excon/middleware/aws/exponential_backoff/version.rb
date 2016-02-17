module Excon
  # Hack to allow us to reference Excon::Middleware::Base without having to require excon when this file is used by gemspec
  module Middleware
    class Base;end
  end

  module Middleware
    module AWS
      class ExponentialBackoff < Excon::Middleware::Base
        VERSION = "0.0.3.pre"
      end
    end
  end
end
