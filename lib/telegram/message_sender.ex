defmodule Engine.Telegram.MessageSender do
  @moduledoc """
  Module for sending messages to telegram
  """

  alias Agala.Provider.Telegram.Helpers
  alias Agala.Conn
  alias Agala.BotParams
  alias Engine.Telegram

  def delivery(
        %Conn{request_bot_params: bot_params, request: %{message: %{from: %{id: id}}}} = _conn,
        messages
      ) do
    messages
    |> Enum.each(fn message ->
      answer(bot_params, id, message)
    end)
  end

  def delivery(
        %Conn{request_bot_params: bot_params, request: %{callback_query: %{from: %{id: id}}}} =
          _conn,
        messages
      ) do
    messages
    |> Enum.each(fn message ->
      answer(bot_params, id, message)
    end)
  end

  def delivery(messages, id, %BotParams{} = bot_params) do
    messages
    |> Enum.each(fn message ->
      answer(bot_params, id, message)
    end)
  end

  def answer(
        %BotParams{name: bot_name} = params,
        telegram_user_id,
        %{text: text, reply_markup: reply_markup} = _message
      ) do
    Agala.response_with(
      %Conn{request_bot_params: params}
      |> Conn.send_to(bot_name)
      |> Helpers.send_message(telegram_user_id, text, reply_markup: reply_markup)
      |> Conn.with_fallback(&message_fallback(&1))
    )
  end

  def answer(%BotParams{name: bot_name} = params, telegram_user_id, %{text: text} = _message) do
    Agala.response_with(
      %Conn{request_bot_params: params}
      |> Conn.send_to(bot_name)
      |> Helpers.send_message(telegram_user_id, text, [])
      |> Conn.with_fallback(&message_fallback(&1))
    )
  end

  def answer(
        %Conn{
          request_bot_params: %{name: bot_name},
          request: %{message: %{from: %{id: user_telegrma_id}}}
        } = _conn,
        message
      ) do
    Agala.response_with(
      %Conn{}
      |> Conn.send_to(bot_name)
      |> Helpers.send_message(user_telegrma_id, message, [])
      |> Conn.with_fallback(&message_fallback(&1))
    )
  end

  defp message_fallback(
         %Conn{
           fallback: %{
             "result" => %{
               "from" => %{"first_name" => first_name, "id" => id, "is_bot" => is_bot},
               "text" => text
             }
           }
         } = _conn
       ) do
    bot_postfix = if is_bot, do: "Bot", else: ""

    Telegram.logger().info(
      "You have just sent message. #{first_name} #{bot_postfix} #{id} : #{text}"
    )
  end

  defp message_fallback(%Conn{fallback: {:error, error}} = _conn) do
    Telegram.logger().info("You have just get error HTTPoison. #{inspect(error)}")
  end

  defp message_fallback(%Conn{fallback: %{"description" => error}} = _conn) do
    Telegram.logger().info("You have just get error response. #{inspect(error)}")
  end
end
