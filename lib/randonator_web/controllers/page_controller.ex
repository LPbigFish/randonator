defmodule RandonatorWeb.PageController do
  use RandonatorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
