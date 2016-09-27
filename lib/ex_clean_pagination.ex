defmodule ExCleanPagination do
  import Plug.Conn

  alias ExCleanPagination.Utils

  def init(opts), do: opts
  def call(%{ assigns: %{ total_items: total_items, max_range: max_range } } = conn, _) do
    conn = put_resp_header(conn, "accept-ranges", "items")

    requested_range = Utils.set_requested_range(
      conn |> get_req_header("range-unit"),
      conn |> get_req_header("range"),
      total_items
    )

    validation_result = validate_range(
      conn,
      requested_range,
      total_items
    )

    handle_validation_result(
      validation_result,
      requested_range,
      total_items,
      max_range
    )
  end
  def call(conn, _) do
    conn
  end

  defp validate_range(conn, {from, to}, _)
       when from > to do
    {:error, conn}
  end
  defp validate_range(conn, {from, _}, total)
       when from > 0 and from >= total do
    {:error, conn}
  end
  defp validate_range(conn, _, _) do
    {:ok, conn}
  end

  defp handle_validation_result({:error, conn}, _, total, _) do
    conn
      |> put_resp_header("content-range", "*/" <> Integer.to_string(total))
      |> resp(:requested_range_not_satisfiable, "invalid pagination range")
      |> halt
  end
  defp handle_validation_result({:ok, conn}, {from, to}, total, max_range) do
    available_to = Enum.min([
      to,
      Utils.decremented_total_items(total),
      from + max_range - 1
    ])

    available_limit = available_to - from + 1

    conn |> set_partial_content(from, available_to, available_limit, total)
  end

  defp set_partial_content(conn, {from, to, limit, total}) do
    conn
      |> assign(:ex_clean_pagination, %{limit: limit, offset: from})
      |> put_resp_header("content-range", Utils.put_resp_content_range(from, to, total))
  end
  defp set_partial_content(%{ status: nil } = conn, from, to, limit, total)
       when total == limit do
    conn
      |> set_partial_content({from, to, limit, total})
      |> put_status(:ok)
  end
  defp set_partial_content(%{ status: nil } = conn, from, to, limit, total)
       when total > limit do
    conn
      |> set_partial_content({from, to, limit, total})
      |> put_status(:partial_content)
  end
  defp set_partial_content(conn, _, _, _, _) do
    conn
  end
end


