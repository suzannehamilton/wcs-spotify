require 'retriable'

class SpotifyRetry
  def self.retry
    Retriable.retriable on: [
      RestClient::RequestTimeout,
      RestClient::BadGateway,
      RestClient::InternalServerError,
      Errno::EHOSTUNREACH,
      Errno::ECONNRESET,
    ], tries: 10 do
      yield
    end
  end
end
