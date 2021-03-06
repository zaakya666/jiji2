# coding: utf-8

module Jiji::Composing::Configurators
  class UtilsConfigurator < AbstractConfigurator

    include Jiji::Utils

    def configure(container)
      container.configure do
        object :time_source, TimeSource.new
      end
    end

  end
end
