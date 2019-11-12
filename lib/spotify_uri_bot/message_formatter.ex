defmodule SpotifyUriBot.MessageFormatter do
  alias SpotifyUriBot.Model.{Track, Artist, Album, Playlist, Show, Episode}

  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InlineQueryResultAudio
  alias ExGram.Model.InputTextMessageContent

  def format(%Track{} = track) do
    """
    🎤 Artist: `#{track.artist}`
    🎵 Song: `#{track.name}`
    📀 Album: `#{track.album}`
    🔗 URI: `#{track.uri}`
    """ <> SpotifyUriBot.Utils.hashtags(track.genres)
  end

  def format(%Artist{} = artist) do
    """
    🎤 Artist: `#{artist.name}`
    🔗 URI: `#{artist.uri}`
    """ <> SpotifyUriBot.Utils.hashtags(artist.genres)
  end

  def format(%Album{} = album) do
    """
    🎤 Artist: `#{album.artist}`
    📀 Album: `#{album.name}`
    📅 Release date: `#{album.release_date}`
    🔗 URI: `#{album.uri}`
    """ <> SpotifyUriBot.Utils.hashtags(album.genres)
  end

  def format(%Playlist{} = playlist) do
    description =
      case playlist.description do
        d when d in ["", nil] -> ""
        d -> "Description: `#{d}`"
      end

    """
    📄 Name: `#{playlist.name}`
    👤 Owner: `#{playlist.owner}`
    🔗 URI: `#{playlist.uri}`
    #{description}
    """
  end

  def format(%Show{} = show) do
    """
    📄 Name: `#{show.name}`
    👤 Publisher: `#{show.publisher}`
    🌐 Languages: `#{Enum.join(show.languages, ", ")}`
    #️⃣ Number of episodes: `#{show.episodes}`
    🔗 URI: `#{show.uri}`
    📗 Description:
    `#{show.description}`
    """
  end

  def format(%Episode{} = episode) do
    """
    📄 Name: `#{episode.name}`
    👤 Publisher: `#{episode.publisher}`
    🌐 Languages: `#{episode.language}`
    🔗 URI: `#{episode.uri}`
    📗 Description:
    `#{episode.description}`
    """
  end

  def get_inline_article(entity, opts \\ [])

  def get_inline_article(%{preview_url: _preview_url} = entity, opts) do
    {message_text, markup} = get_message_with_markup(entity)

    %InlineQueryResultAudio{
      type: "audio",
      id: entity.uri,
      title: opts[:title],
      performer: opts[:description],
      audio_url: entity.preview_url,
      input_message_content: %InputTextMessageContent{
        message_text: message_text,
        parse_mode: "Markdown"
      },
      reply_markup: markup
    }
  end

  def get_inline_article(entity, opts) do
    {message_text, markup} = get_message_with_markup(entity)

    %InlineQueryResultArticle{
      type: "article",
      id: entity.uri,
      title: opts[:title],
      input_message_content: %InputTextMessageContent{
        message_text: message_text,
        parse_mode: "Markdown"
      },
      reply_markup: markup,
      description: opts[:description] || ""
    }
  end

  def get_message_with_markup(entity) do
    message_text = format(entity)
    markup = SpotifyUriBot.Utils.generate_url_buttons(entity.href, entity.uri)
    {message_text, markup}
  end
end
