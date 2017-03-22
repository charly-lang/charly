const net_response_flush = __internal__method("net_response_flush")
const net_response_close = __internal__method("net_response_close")
const net_response_write = __internal__method("net_response_write")
const net_response_write_file = __internal__method("net_response_write_file")

class Response {
  property response_id
  property status_code
  property headers

  func constructor(data) {
    @response_id = data.__response_id
    @status_code = data.status_code
    @headers = data.headers
  }

  /**
   * Flushes the output
   **/
  func flush() {
    net_response_flush(@response_id)
    self
  }

  /**
   * Closes the response, writing headers and body if not done yet
   **/
  func close() {
    net_response_close(@response_id)
    self
  }

  /**
   * Writes the string representation of data to the response
   **/
  func write(data) {
    net_response_write(@response_id, data.to_s())
    self
  }

  /**
   * Writes a given File object to the response
   **/
  func write_file(path) {
    net_response_write_file(@response_id, path)
  }

  func set_header(name, value) {
    const values = @headers[name]

    if typeof values == "Array" {
      values << value.to_s()
    } else {
      @headers[name] = [value.to_s()]
    }

    self
  }
}

export = Response
