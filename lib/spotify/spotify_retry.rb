require 'retriable'

class SpotifyRetry
  def self.retry
    Retriable.retriable on: [RestClient::RequestTimeout, RestClient::BadGateway, RestClient::InternalServerError, Errno::EHOSTUNREACH], tries: 3 do
      yield
    end
  end
end
