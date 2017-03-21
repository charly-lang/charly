require "../**"
require "colorize"
require "http"

module Charly::Internals

  # Pool of all current open servers
  HTTP_SERVERS = {} of UInt64 => Server

  class Server
    @@next_server_id = 1_u64 # TODO: Put this at a more suitable place

    def self.next_server_id
      @@next_server_id
    end

    def self.next_server_id=(value)
      @@next_server_id = value
    end

    property server : HTTP::Server
    property handler : TObject
    property on_request : Proc(TObject, TObject, Void)?
    property on_listen : Proc(Void)?
    property on_close : Proc(Void)?

    def initialize(@handler, address, port)
      @server = HTTP::Server.new(address, port) do |context|
        wrapped_request = wrap_request context.request
        wrapped_response = wrap_response context.response
        @on_request.try &.call wrapped_request, wrapped_response
        copy_to_response wrapped_response, context.response
      end
    end

    def on_request(&block : Proc(TObject, TObject, Void))
      @on_request = block
    end

    def on_listen(&block)
      @on_listen = block
    end

    def on_close(&block)
      @on_close = block
    end

    def listen
      @server.listen
    end

    def close
      @server.close
    end

    # Creates a TObject from a HTTP::Request
    private def wrap_request(req : HTTP::Request)
      TObject.new do |data|
        data.init "body",           TString.new  req.body.to_s
        data.init "content_length", TNumeric.new req.content_length || 0
        data.init "host",           TString.new  req.host || ""
        data.init "ignore_body",    TBoolean.new req.ignore_body?
        data.init "keep_alive",     TBoolean.new req.keep_alive?
        data.init "method",         TString.new  req.method
        data.init "path",           TString.new  req.path
        data.init "query",          TString.new  req.query || ""
        data.init "resource",       TString.new  req.resource
        data.init "version",        TString.new  req.version

        data.init "query_params", TObject.new { |data|
          req.query_params.each do |(name, value)|
            data.init name, TString.new value
          end
        }

        data.init "headers", TObject.new { |data|
          req.headers.each do |(name, value)|
            values = TArray.new value.map { |field| TString.new(field).as(BaseType) }
            data.init name, values
          end
        }

        data.init "cookies", TObject.new { |data|
          req.cookies.each do |cookie|
            data.init cookie.name, TObject.new { |data|
              data.init "value",      TString.new cookie.value
              data.init "path",       TString.new cookie.path
              data.init "secure",     TBoolean.new cookie.secure
              data.init "http_only",  TBoolean.new cookie.http_only

              expires, domain, extension = cookie.expires, cookie.domain, cookie.extension

              data.init "expires", TNumeric.new expires.epoch if expires
              data.init "domain", TString.new domain if domain
              data.init "extension", TString.new extension if extension
            }
          end
        }
      end
    end

    # Creates a TObject from a HTTP::Server::Response
    private def wrap_response(res : HTTP::Server::Response)
      TObject.new do |data|
        data.init "body",           TString.new ""
        data.init "status_code",    TNumeric.new 200
      end
    end

    # Copies values from a TObject into a HTTP::Server::Response object
    private def copy_to_response(source : TObject, res : HTTP::Server::Response)
      res.output.print source.data.get("body").as(TString).value rescue ""
      res.status_code = source.data.get("status_code").as(TNumeric).value.to_i32 rescue 200
    end
  end

  charly_api "net_create", TObject, TString, TNumeric do |handler, address, port|
    address, port = address.value, port.value.to_i32

    server = Server.new handler, address, port
    event_handler = handler.data.get "invoke"

    server.on_request do |request, response|
      invoke = event_handler.as(TFunc)
      visitor.run_function_call(
        invoke,
        [
          TString.new("request"),
          TArray.new([request, response] of BaseType)
        ] of BaseType,
        server.handler,
        invoke.parent_scope,
        context,
        call.location_start
      )
    end

    server.on_listen do
      invoke = event_handler.as(TFunc)
      visitor.run_function_call(
        invoke,
        [
          TString.new("listen"),
          TArray.new
        ] of BaseType,
        server.handler,
        invoke.parent_scope,
        context,
        call.location_start
      )
    end

    server.on_close do
      invoke = event_handler.as(TFunc)
      visitor.run_function_call(
        invoke,
        [
          TString.new("close"),
          TArray.new
        ] of BaseType,
        server.handler,
        invoke.parent_scope,
        context,
        call.location_start
      )
    end

    HTTP_SERVERS[Server.next_server_id] = server
    return TNumeric.new(Server.next_server_id).tap do
      Server.next_server_id += 1
    end
  end

  charly_api "net_listen", TNumeric do |id|
    id = id.value.to_u64

    server = HTTP_SERVERS[id]?

    if server
      server.on_listen.try &.call
      server.listen
    end

    TNull.new
  end

  charly_api "net_close", TNumeric do |id|
    id = id.value.to_u64

    server = HTTP_SERVERS[id]?

    if server
      server.close
      server.on_close.try &.call
    end

    TNull.new
  end

end
