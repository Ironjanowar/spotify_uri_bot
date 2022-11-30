defmodule SpotifyUriBot.Images do
  require Image.Color

  @write_options [
    progressive: true,
    suffix: ".png",
    quality: 100,
    strip_metadata: true
  ]

  @base_text_options [
    font: "Montserrat",
    font_weight: :bold,
    font_size: 70,
    background_fill_opacity: 0.8
  ]

  @base_genres_options [
    font: "Montserrat",
    font_weight: :bold,
    font_size: 8,
    background_fill_opacity: 0.8
  ]

  defp luminance(color) do
    [r, g, b] =
      Enum.map(color, fn val ->
        val = val / 255
        if val <= 0.04045, do: val / 12.92, else: Float.pow((val + 0.055) / 1.055, 2.4)
      end)

    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  defp filter_color([r, g, b]) do
    # Exclude colors close to pure white
    is_not_white = !(r >= 250 && g >= 250 && b >= 250)
    # Exclude colors close to pure black
    is_not_black = !(r <= 6 && g <= 6 && b <= 6)
    # Allow colors close to lighter shades
    is_lighter_shade = (r + g + b) / 255 < 2.2
    # Allow colors close to darker shades
    is_darker_shade = (r + g + b) / 255 > 0.7

    if is_not_white && is_not_black &&
         is_lighter_shade && is_darker_shade,
       do: [r, g, b]
  end

  defp find_best_dominant_colors(image, option) do
    # Resize cover to a minimal size to get appropiate colors
    {:ok, small} = Image.resize(image, 0.025)

    # Color for reference
    dominant_color = Image.dominant_color(small)

    # Sample colors
    dominant_colors =
      Enum.map(32..128, fn bins -> Image.dominant_color(small, bins: bins) end)
      |> Enum.filter(fn color -> filter_color(color) end)
      |> Enum.uniq()
      |> Enum.sort(:desc)

    case option do
      :plain ->
        with [] <- dominant_colors do
          # Since all colors were close to white and black none were sampled
          dominant_color
        else
          _ ->
            # Decide between brightest and darkest colors
            [[rB, gB, bB] | _] = dominant_colors
            [[rD, gD, bD] | _] = Enum.sort(dominant_colors, :asc)
            [r, g, b] = dominant_color
            brightest_color_distance = abs(r + g + b - (rB + gB + bB))
            darkest_color_distance = abs(r + g + b - (rD + gD + bD))

            if brightest_color_distance > darkest_color_distance,
              do: [rD, gD, bD],
              else: [rB, gB, bB]
        end

      :gradient ->
        with [] <- dominant_colors do
          # Since all colors were close to white and black none were sampled
          {dominant_color, dominant_color}
        else
          _ ->
            # Decide between brightest and darkest colors
            [[rB, gB, bB] | _] = dominant_colors
            [[rD, gD, bD] | _] = Enum.sort(dominant_colors, :asc)

            if luminance([rB, gB, bB]) > luminance([rD, gD, bD]),
              do: {[rB, gB, bB], [rD, gD, bD]},
              else: {[rD, gD, bD], [rB, gB, bB]}
        end
    end
  end

  defp select_text_color(text, colors) do
    avg_luminance =
      case colors do
        {start_color, finish_color} -> (luminance(start_color) + luminance(finish_color)) / 2
        color -> luminance(color)
      end

    if avg_luminance > 0.179,
      do:
        if(byte_size(text) == 1,
          do: "#333333",
          else: :transparent
        ),
      else: :white
  end

  defp adjust_text(text_image, width_to_adjust),
    do:
      if(Image.width(text_image) > width_to_adjust,
        do:
          Image.resize(text_image, width_to_adjust / Image.width(text_image))
          |> elem(1),
        else:
          {:ok, text_image}
          |> elem(1)
      )

  defp text_options(text, dominant_color),
    do: [{:text_fill_color, select_text_color(text, dominant_color)} | @base_text_options]

  defp genres_text_options(text, dominant_color),
    do: [{:text_fill_color, select_text_color(text, dominant_color)} | @base_genres_options]

  def renderCardFromEntity(entity, option) do
    [song_cover_data | _] = entity.images
    {:ok, response} = Tesla.get(song_cover_data["url"])

    # Find best matching dominant color for cover
    {:ok, cover} = Image.open(response.body)
    dominant_colors_result = find_best_dominant_colors(cover, option)

    # Resize cover
    {:ok, cover} = Image.resize(cover, 0.75)

    # Cover dimensions and options
    cover_offset = 30
    cover_width = Image.width(cover)
    cover_height = Image.height(cover)

    # General text options
    text_offset_x = cover_width + cover_offset * 2
    text_offset_y = 40
    text_spacing = 50
    text_area_width = round(cover_width * 0.84)

    # Canvas dimensions and options
    canvas_width = cover_width + text_area_width + cover_offset * 3
    canvas_height = cover_height + cover_offset * 2

    # Elements position options
    cover_pos = [x: cover_offset, y: cover_offset]
    song_name_pos = [x: text_offset_x, y: text_offset_y]
    album_name_pos = [x: text_offset_x, y: text_offset_y * 2 + text_spacing]
    artist_name_pos = [x: text_offset_x, y: text_offset_y * 3 + text_spacing * 2]
    genres_pos = [x: text_offset_x, y: canvas_height - cover_offset - 15]

    # Create canvas with gradient background
    {:ok, canvas} =
      with {:ok, canvas} <- Image.new(canvas_width, canvas_height),
           {start_color, finish_color} <- dominant_colors_result do
        Image.linear_gradient(canvas, start_color, finish_color)
      else
        _ ->
          Image.new(canvas_width, canvas_height, color: dominant_colors_result)
      end

    # {:ok, canvas} = Image.compose(canvas, gradient)

    # Create song name, album name and artist name elements
    {:ok, canvas} =
      with {:ok, song_name} <-
             Image.Text.text(entity.name, text_options(entity.name, dominant_colors_result)),
           {:ok, album_name} <-
             Image.Text.text(entity.album, text_options(entity.album, dominant_colors_result)),
           {:ok, artist_name} <-
             Image.Text.text(entity.artist, text_options(entity.artist, dominant_colors_result)) do
        if entity.album_type != "single",
          do:
            Image.compose(canvas, adjust_text(song_name, text_area_width), song_name_pos)
            |> elem(1)
            |> Image.compose(adjust_text(album_name, text_area_width), album_name_pos)
            |> elem(1)
            |> Image.compose(adjust_text(artist_name, text_area_width), artist_name_pos),
          else:
            Image.compose(canvas, adjust_text(song_name, text_area_width), song_name_pos)
            |> elem(1)
            |> Image.compose(adjust_text(artist_name, text_area_width), artist_name_pos)
      end

    # Join genres if multiple
    genres_text =
      Enum.map_join(entity.genres, " ", fn genre ->
        "#" <> (String.split(genre) |> Enum.join())
      end)

    # If there is at least one genre, canvas is modified
    {:ok, canvas} =
      with true <- String.length(genres_text) > 0,
           {_, finish_color} <- dominant_colors_result,
           {:ok, genres} <-
             Image.Text.text(genres_text, genres_text_options(genres_text, finish_color)) do
        Image.compose(canvas, adjust_text(genres, text_area_width), genres_pos)
      else
        false ->
          {:ok, canvas}

        dominant_colors_result ->
          {:ok, genres} =
            Image.Text.text(genres_text, genres_text_options(genres_text, dominant_colors_result))

          Image.compose(canvas, adjust_text(genres, text_area_width), genres_pos)
      end

    # Add cover to canvas and write
    Image.compose(canvas, cover, cover_pos)
    |> elem(1)
    |> Image.write(:memory, @write_options)
  end
end
