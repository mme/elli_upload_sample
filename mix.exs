defmodule Elliupload.Mixfile do
  use Mix.Project

  def project do
    [ app: :elliupload,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ registered: [:elli_upload],
        mod: { Elli.Upload, [] } ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ { :elli, github: "knutin/elli", branch: "handover"},
      { :erlmultipart, github: "mme/erlmultipart" }]
  end
end
