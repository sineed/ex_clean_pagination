defmodule ExCleanPaginationTest do
  use ExUnit.Case

  import Plug.Conn

  setup do
    conn = %Plug.Conn{}
      |> assign(:total_items, 101)
      |> assign(:max_range, 100)

    {:ok, [conn: conn]}
  end

  test "rangeless request range works normally if max_range >= total", %{conn: conn} do
    conn = conn
      |> assign(:total_items, 100)
      |> ExCleanPagination.call(nil)

    assert conn.status == 200
    assert get_resp_header(conn, "accept-ranges") == ["items"]
  end

  test "rangeless request truncates if max_range < total", %{conn: conn} do
    conn = conn
      |> ExCleanPagination.call(nil)
    assert conn.status == 206
    assert get_resp_header(conn, "accept-ranges") == ["items"]
    assert get_resp_header(conn, "content-range") == ["0-99/101"]
    assert conn.assigns[:ex_clean_pagination] == %{limit: 100, offset: 0}
  end

  test "an acceptable range succeeds", %{conn: conn} do
    conn = conn
      |> put_req_header("range-unit", "items")
      |> put_req_header("range", "0-98")
      |> ExCleanPagination.call(nil)

    assert conn.status == 206
    assert get_resp_header(conn, "accept-ranges") == ["items"]
    assert get_resp_header(conn, "content-range") == ["0-98/101"]
    assert conn.assigns[:ex_clean_pagination] == %{limit: 99, offset: 0}
  end

  test "an oversized range is truncated", %{conn: conn} do
    conn = conn
      |> put_req_header("range-unit", "items")
      |> put_req_header("range", "0-100")
      |> ExCleanPagination.call(nil)

    assert conn.status == 206
    assert get_resp_header(conn, "accept-ranges") == ["items"]
    assert get_resp_header(conn, "content-range") == ["0-99/101"]
    assert conn.assigns[:ex_clean_pagination] == %{limit: 100, offset: 0}
  end

  test "passes along exceptional status codes", %{conn: conn} do
    conn = conn
      |> put_req_header("range-unit", "items")
      |> put_req_header("range", "0-99")
      |> put_status(500)
      |> ExCleanPagination.call(nil)

    assert conn.status == 500
    assert get_resp_header(conn, "accept-ranges") == ["items"]
    refute get_resp_header(conn, "content-range") == ["0-99/101"]
    refute conn.assigns[:ex_clean_pagination]
  end

  test "reports infinite/unknown collection", %{conn: conn} do
    conn = conn
      |> put_req_header("range-unit", "items")
      |> put_req_header("range", "0-9")
      |> assign(:total_items, :infinity)
      |> ExCleanPagination.call(nil)

    assert get_resp_header(conn, "content-range") == ["0-9/*"]
    assert conn.assigns[:ex_clean_pagination] == %{limit: 10, offset: 0}
  end

  test "refuses offside ranges", %{conn: conn} do
    conn = conn
      |> put_req_header("range-unit", "items")
      |> put_req_header("range", "1-0")
      |> ExCleanPagination.call(nil)

    assert conn.status == 416
    assert conn.halted
    assert get_resp_header(conn, "accept-ranges") == ["items"]
    assert get_resp_header(conn, "content-range") == ["*/101"]
    refute conn.assigns[:ex_clean_pagination]
  end

  test "refuses range start past end", %{conn: conn} do
    conn = conn
      |> put_req_header("range-unit", "items")
      |> put_req_header("range", "101-")
      |> ExCleanPagination.call(nil)

    assert conn.status == 416
    assert conn.halted
    assert get_resp_header(conn, "accept-ranges") == ["items"]
    assert get_resp_header(conn, "content-range") == ["*/101"]
    refute conn.assigns[:ex_clean_pagination]
  end

  test "allows one-item requests", %{conn: conn} do
    conn = conn
      |> put_req_header("range-unit", "items")
      |> put_req_header("range", "0-0")
      |> ExCleanPagination.call(nil)

    assert conn.status == 206
    assert get_resp_header(conn, "accept-ranges") == ["items"]
    assert get_resp_header(conn, "content-range") == ["0-0/101"]
    assert conn.assigns[:ex_clean_pagination] == %{limit: 1, offset: 0}
  end

  test "allows one-item requests when there is inly one item", %{conn: conn} do
    conn = conn
      |> put_req_header("range-unit", "items")
      |> put_req_header("range", "0-0")
      |> assign(:total_items, 1)
      |> ExCleanPagination.call(nil)

    assert conn.status == 200
    assert get_resp_header(conn, "accept-ranges") == ["items"]
    assert get_resp_header(conn, "content-range") == ["0-0/1"]
    assert conn.assigns[:ex_clean_pagination] == %{limit: 1, offset: 0}
  end

  test "handles ranges beyond collection length via truncation", %{conn: conn} do
    conn = conn
      |> put_req_header("range-unit", "items")
      |> put_req_header("range", "50-200")
      |> ExCleanPagination.call(nil)

    assert conn.status == 206
    assert get_resp_header(conn, "accept-ranges") == ["items"]
    assert get_resp_header(conn, "content-range") == ["50-100/101"]
    assert conn.assigns[:ex_clean_pagination] == %{limit: 51, offset: 50}
  end

  test "omitting the end number asks for everything", %{conn: conn} do
    conn = conn
      |> put_req_header("range-unit", "items")
      |> put_req_header("range", "50-")
      |> assign(:total_items, :infinity)
      |> assign(:max_range, 1000000)
      |> ExCleanPagination.call(nil)

    assert conn.status == 206
    assert get_resp_header(conn, "accept-ranges") == ["items"]
    assert get_resp_header(conn, "content-range") == ["50-1000049/*"]
    assert conn.assigns[:ex_clean_pagination] == %{limit: 1000000, offset: 50}
  end

end
