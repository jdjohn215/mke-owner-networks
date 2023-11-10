defmodule WhoOwnsWhatWeb.Helpers do
  @number_comma_regex ~r/\B(?=(\d{3})+(?!\d))/

  def formatted_dollars(number) do
    Regex.replace(@number_comma_regex, "#{number}", ",")
  end
end
