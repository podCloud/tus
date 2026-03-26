# Tus

A maintained fork of [jpscaletti/tus](https://github.com/jpscaletti/tus) (original repo removed).

An implementation of a *[tus](https://tus.io/)* **server** in Elixir.

<img alt="Tus logo" src="https://github.com/tus/tus.io/blob/master/assets/img/tus1.png?raw=true" width="30%" align="right" />

> **tus** is a protocol based on HTTP for *resumable file uploads*. Resumable
> means that an upload can be interrupted at any moment and can be resumed without
> re-uploading the previous data again.
>
> An interruption may happen willingly, if the user wants to pause,
> or by accident in case of an network issue or server outage.

It's currently capable of accepting uploads with arbitrary sizes and storing them locally
on disk. Due to its modularization and extensibility, support for any cloud provider
can be easily added.

## Fork changes

This fork fixes several issues found in the original 0.1.3 release:

- **Storage: fsync on write** — Chunks are synced to disk before the server responds. Prevents race conditions when disk I/O is saturated (the server would acknowledge a chunk before it was actually written, causing the client to retry in a loop).
- **Storage: removed `:delayed_write`** — Erlang-level write buffering was adding an extra layer of caching on top of the OS page cache, making the sync problem worse.
- **Storage: write error handling** — Write errors are now propagated instead of being silently ignored.
- **Patch: full body read** — `read_body` returns `{:more, data, conn}` for large bodies. The original code matched both `:ok` and `:more` with `{_, data, conn}`, silently truncating chunks larger than Plug's read limit (~8 MB).
- **Post: off-by-one on max_size** — A file of exactly `max_size` bytes was rejected. Fixed to `<=`.
- **Application: removed deprecated `Supervisor.Spec.worker/3`**.

## Original author

Created by [Juan-Pablo Scaletti](https://github.com/jpscaletti) — original repo at `github.com/jpscaletti/tus` (removed by author).

## Features

This library implements the core TUS API v1.0.0 protocol and the following extensions:

- Creation Protocol (http://tus.io/protocols/resumable-upload.html#creation). Deferring the upload's length is not possible.
- Termination Protocol (http://tus.io/protocols/resumable-upload.html#termination)

## Installation

Add this repo to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tus, github: "podCloud/tus", branch: "main"},
  ]
end
```

## Usage

**1. Add a controller**

```elixir
defmodule DemoWeb.UploadController do
  use DemoWeb, :controller
  use Tus.Controller

  # Optional: called when upload starts
  def on_begin_upload(file) do
    :ok  # or {:error, reason} to reject
  end

  # Optional: called when upload completes
  def on_complete_upload(file) do
    # process the uploaded file
  end
end
```

**2. Add routes**

```elixir
scope "/files", DemoWeb do
    options "/",          UploadController, :options
    match :head, "/:uid", UploadController, :head
    post "/",             UploadController, :post
    patch "/:uid",        UploadController, :patch
    delete "/:uid",       UploadController, :delete
end
```

**3. Configure**

```elixir
config :tus, controllers: [DemoWeb.UploadController]

config :tus, DemoWeb.UploadController,
  storage: Tus.Storage.Local,
  base_path: "priv/static/files/",
  cache: Tus.Cache.Memory,
  max_size: 1024 * 1024 * 20  # 20 MB
```

## License

BSD 3-Clause — see [LICENSE](LICENSE).
