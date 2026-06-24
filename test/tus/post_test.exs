defmodule Tus.PostTest do
  use ExUnit.Case, async: true

  describe "parse_metadata/1" do
    test "decodes a standard `key base64(value)` pair" do
      meta = "filename " <> Base.encode64("hello.mp3")
      assert Tus.Post.parse_metadata(meta) == [{"filename", "hello.mp3"}]
    end

    test "decodes several comma-separated pairs" do
      meta = "filename " <> Base.encode64("hello.mp3") <> ", filetype " <> Base.encode64("audio/mpeg")

      assert Tus.Post.parse_metadata(meta) == [
               {"filename", "hello.mp3"},
               {"filetype", "audio/mpeg"}
             ]
    end

    # The TUS spec allows a metadata key with no value. tus-js-client emits a
    # bare key (no trailing space) whenever the value is an empty string, which
    # is exactly what `filetype: file.type` produces when the browser cannot
    # determine the MIME type. This used to raise a MatchError and return a 500.
    test "handles a valueless key (bare key, no value)" do
      assert Tus.Post.parse_metadata("filetype") == [{"filetype", ""}]
    end

    test "handles a valueless key mixed with valued ones" do
      meta = "filename " <> Base.encode64("hello.mp3") <> ",filetype"

      assert Tus.Post.parse_metadata(meta) == [
               {"filename", "hello.mp3"},
               {"filetype", ""}
             ]
    end

    test "does not crash on an invalid base64 value" do
      assert Tus.Post.parse_metadata("filetype !!!not-base64!!!") == [{"filetype", ""}]
    end
  end
end
