defmodule SpotifyUriBot.Bot do
  @bot :spotify_uri_bot

  use ExGram.Bot,
    name: @bot

  alias SpotifyUriBot.MessageFormatter

  require Logger

  middleware(SpotifyUriBot.Middleware.Stats)
  middleware(SpotifyUriBot.Middleware.Admin)
  middleware(SpotifyUriBot.Middleware.IgnoreBotMessage)

  def bot(), do: @bot

  def handle({:command, "start", _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:inline_query, %{query: ""}}, _context), do: :ok

  def handle({:inline_query, %{query: text}}, context) do
    case generate_inline_options(text) do
      {:ok, articles} -> answer_inline_query(context, articles)
      _ -> Logger.debug("Ignoring query #{text}")
    end
  end

  def handle(
        {:text, text, %{message_id: message_id}},
        %{extra: %{message_from_bot: false}} = context
      ) do
    case get_entity(text) do
      {:ok, _, result} ->
        {message, markup} = MessageFormatter.get_message_with_markup(result)

        answer(context, message,
          parse_mode: "Markdown",
          reply_to_message_id: message_id,
          reply_markup: markup || ""
        )

      _ ->
        :ok
    end
  end

  # Admin commands
  def handle({:callback_query, %{data: "stats:refresh"}}, %{extra: %{is_admin: true}} = context) do
    {message, markup} = generate_stats_message()
    edit(context, :inline, message, parse_mode: "Markdown", reply_markup: markup)
  end

  def handle({:command, "stats", _}, %{extra: %{is_admin: true}} = context) do
    {message, markup} = generate_stats_message()
    answer(context, message, parse_mode: "Markdown", reply_markup: markup)
  end

  def handle(_, cnt) do
    Logger.debug("Ignoring update:\n#{inspect(cnt)}")
    :ignoring
  end

  def generate_stats_message(), do: SpotifyUriBot.Stats.get_stats() |> generate_stats_message()

  def generate_stats_message(%{users: users, groups: groups}) do
    users_count = Enum.count(users)
    groups_count = Enum.count(groups)
    date = Timex.now("Europe/Madrid")

    day = [date.year, date.month, date.day] |> Enum.map(&pad_lead/1) |> Enum.join("-")
    hour = [date.hour, date.minute, date.second] |> Enum.map(&pad_lead/1) |> Enum.join(":")

    date_string = "#{day} #{hour}"

    message = """
    Number of users and groups that have used the bot (_#{date_string}_):
    Users:  *#{users_count}*
    Groups: *#{groups_count}*
    """

    markup = ExGram.Dsl.create_inline([[[text: "Refresh", callback_data: "stats:refresh"]]])

    {message, markup}
  end

  # Private
  defp pad_lead(num) do
    num
    |> to_string()
    |> String.pad_leading(2, "0")
  end

  defp generate_inline_options(text) do
    case get_entity(text) do
      {:ok, :track, track} ->
        {:ok,
         [
           MessageFormatter.get_inline_article(track,
             title: track.name,
             description: track.artist
           )
         ]}

      {:ok, :artist, artist} ->
        artist_article =
          MessageFormatter.get_inline_article(artist,
            title: "Share artist",
            description: artist.name
          )

        track_articles =
          Enum.map(
            artist.top_tracks,
            &MessageFormatter.get_inline_article(&1, title: &1.name, description: &1.artist)
          )

        {:ok, [artist_article | track_articles]}

      {:ok, :album, album} ->
        album_article =
          MessageFormatter.get_inline_article(album, title: "Share album", description: album.name)

        track_articles =
          Enum.map(
            album.tracks,
            &MessageFormatter.get_inline_article(&1, title: &1.name, description: &1.artist)
          )

        {:ok, [album_article | track_articles]}

      {:ok, :playlist, playlist} ->
        playlist_article =
          MessageFormatter.get_inline_article(playlist,
            title: "Share playlist",
            description: playlist.name
          )

        {:ok, [playlist_article]}

      {:ok, :show, show} ->
        show_article =
          MessageFormatter.get_inline_article(show, title: "Share show", description: show.name)

        episode_articles =
          Enum.map(
            show.episodes,
            &MessageFormatter.get_inline_article(&1, title: &1.name, description: &1.publisher)
          )

        {:ok, [show_article | episode_articles]}

      {:ok, :episode, episode} ->
        episode_article =
          MessageFormatter.get_inline_article(episode,
            title: episode.name,
            description: episode.publisher
          )

        {:ok, [episode_article]}

      {:no_uri, text} ->
        case SpotifyUriBot.Server.search(text) do
          {:ok, _, {_, entity}} ->
            entity_articles =
              Enum.map(
                entity,
                &MessageFormatter.get_inline_article(&1,
                  title: &1.title,
                  description: &1.description
                )
              )

            {:ok, entity_articles}

          _ ->
            :ignore
        end

      _ ->
        :ignore
    end
  end

  defp get_entity(text) do
    case SpotifyUriBot.Utils.parse_text(text) do
      {:ok, :track, uri} ->
        {:ok, track} = SpotifyUriBot.Server.get_track(uri)
        Logger.debug("Message generated for #{uri}")
        {:ok, :track, track}

      {:ok, :album, uri} ->
        {:ok, album} = SpotifyUriBot.Server.get_album(uri)
        Logger.debug("Message generated for #{uri}")
        {:ok, :album, album}

      {:ok, :artist, uri} ->
        {:ok, artist} = SpotifyUriBot.Server.get_artist(uri)
        Logger.debug("Message generated for #{uri}")
        {:ok, :artist, artist}

      {:ok, :playlist, uri} ->
        {:ok, playlist} = SpotifyUriBot.Server.get_playlist(uri)
        Logger.debug("Message generated for #{uri}")
        {:ok, :playlist, playlist}

      {:ok, :show, uri} ->
        {:ok, show} = SpotifyUriBot.Server.get_show(uri)
        Logger.debug("Message generated for #{uri}")
        {:ok, :show, show}

      {:ok, :episode, uri} ->
        {:ok, episode} = SpotifyUriBot.Server.get_episode(uri)
        Logger.debug("Message generated for #{uri}")
        {:ok, :episode, episode}

      {:error, message} ->
        Logger.debug(message)
        :no_uri

      _ ->
        Logger.debug("Not URI or URL: #{text}")
        {:no_uri, text}
    end
  end
end
