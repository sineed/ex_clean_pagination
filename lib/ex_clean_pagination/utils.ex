defmodule ExCleanPagination.Utils do
  def set_requested_range(["items"], [range|_], total) do
    ~r/(?<from>\d+)-(?<to>\d*)/
      |> Regex.named_captures(range)
      |> set_requested_range(total)
  end
  def set_requested_range(_unit, _range, total) do
    set_requested_range(:nil, total)
  end
  defp set_requested_range(:nil, total) do
    {0, Enum.max([0, total - 1])}
  end
  defp set_requested_range(%{ "from" => from, "to" => "" }, _total) do
    {String.to_integer(from), :infinity}
  end
  defp set_requested_range(%{ "from" => from, "to"=> to }, _total) do
    {String.to_integer(from), String.to_integer(to)}
  end

  def decremented_total_items(:infinity) do
    :infinity
  end
  def decremented_total_items(total_items) do
    total_items - 1
  end

  def put_resp_content_range(from, to, total) do
     join_range_values(from, to) |> content_range(total)
  end

  defp join_range_values(from, to) do
    Integer.to_string(from) <> "-" <> Integer.to_string(to)
  end

  defp content_range(range, :infinity) do
    range |> content_range("*")
  end
  defp content_range(range, total)
       when is_integer(total) do
    range |> content_range(Integer.to_string(total))
  end
  defp content_range(range, total) do
    range <> "/" <> total
  end
end
