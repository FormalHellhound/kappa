require 'cgi'

module Kappa::V2
  # Streams are video broadcasts that are currently live. They belong to a user and are part of a channel.
  # @see .get Stream.get
  # @see Streams
  # @see Channel
  class Stream
    include Connection
    include Kappa::IdEquality

    # @private
    def initialize(hash)
      @id = hash['_id']
      @broadcaster = hash['broadcaster']
      @game_name = hash['game']
      @name = hash['name']
      @viewer_count = hash['viewers']
      @preview_url = hash['preview']
      @channel = Channel.new(hash['channel'])
    end

    # Get a live stream by name.
    # @example
    #   s = Stream.get('lagtvmaximusblack')
    #   s.nil?          # => false (stream is live)
    #   s.game_name     # => "StarCraft II: Heart of the Swarm"
    #   s.viewer_count  # => 2403
    # @example
    #   s = Strearm.get('destiny')
    #   s.nil?          # => true (stream is offline)
    # @param stream_name [String] The name of the stream to get. This is the same as the channel or user name.
    # @return [Stream] A valid `Stream` object if the stream exists and is currently live, `nil` otherwise.
    def self.get(stream_name)
      encoded_name = CGI.escape(stream_name)
      json = connection.get("streams/#{encoded_name}")
      stream = json['stream']
      if json['status'] == 404 || !stream
        nil
      else
        new(stream)
      end
    end

    # @return [Fixnum] Unique Twitch ID.
    attr_reader :id

    # @example
    #   "fme", "xsplit", "obs"
    # @return [String] The broadcasting software used for this stream.
    attr_reader :broadcaster
    
    # @return [String] The name of the game currently being streamed.
    attr_reader :game_name

    # @return [String] The unique Twitch name for this stream.
    attr_reader :name

    # @return [Fixnum] The number of viewers currently watching the stream.
    attr_reader :viewer_count

    # @return [String] URL of a preview screenshot taken from the video stream.
    attr_reader :preview_url

    # @note This does not incur any web requests.
    # @return [Channel] The `Channel` associated with this stream.
    attr_reader :channel
  end

  # Query class used for finding featured streams or streams meeting certain criteria.
  # @see Stream
  class Streams
    include Connection

    # @private
    # Private until implemented
    def self.all
      # TODO
    end

    # Get a list of streams for a specific game, for a set of channels, or by other criteria.
    # @example
    #   Streams.find(:game => 'League of Legends', :limit => 50)
    # @example
    #   Streams.find(:channel => ['fgtvlive', 'incontroltv', 'destiny'])
    # @example
    #   Streams.find(:game => 'Diablo III', :channel => ['nl_kripp', 'protech'])
    # @param :game [String/Game] Only return streams currently streaming the specified game.
    # @param :channel [Array<String/Channel>] Only return streams for these channels.
    #   If a channel is not currently streaming, it is omitted. You must specify an array of channels
    #   or channel names. If you want to find the stream for a single channel, see {Stream.get}.
    # @param :embeddable [Boolean] TODO
    # @param :hls [Boolean] TODO
    # @param :limit [Fixnum] (optional) Limit on the number of results returned. Default: no limit.
    # @param :offset [Fixnum] (optional) Offset into the result set to begin enumeration. Default: `0`.
    # @see https://github.com/justintv/Twitch-API/blob/master/v2_resources/streams.md#get-streams GET /streams
    # @raise [ArgumentError] If `args` does not specify a search criteria (`:game`, `:channel`, `:embeddable`, or `:hls`).
    # @return [Array<Stream>] List of streams matching the specified criteria.
    def self.find(args)
      check = args.dup
      check.delete(:limit)
      check.delete(:offset)
      raise ArgumentError if check.empty?

      # TODO: Support Kappa::Vx::Game object for the :game param.
      # TODO: Support Kappa::Vx::Channel object for the :channel param.

      params = {}

      if args[:channel]
        params[:channel] = args[:channel].join(',')
      end

      if args[:game]
        params[:game] = args[:game]
      end

      limit = args[:limit]
      if limit && (limit < 100)
        params[:limit] = limit
      else
        params[:limit] = 100
        limit = 0
      end

      return connection.accumulate(
        :path => 'streams',
        :params => params,
        :json => 'streams',
        :class => Stream,
        :limit => limit
      )
    end

    # Get the list of currently featured (promoted) streams. This includes the list of streams shown on the Twitch homepage.
    # @note There is no guarantee of how many streams are featured at any given time.
    # @example
    #   Streams.featured
    # @example
    #   Streams.featured(:limit => 5)
    # @param :hls [Boolean] (optional) TODO
    # @param :limit [Fixnum] (optional) Limit on the number of results returned. Default: no limit.
    # @param :offset [Fixnum] (optional) Offset into the result set to begin enumeration. Default: `0`.
    # @see https://github.com/justintv/Twitch-API/blob/master/v2_resources/streams.md#get-streamsfeatured GET /streams/featured
    # @return [Array<Stream>] List of currently featured streams.
    def self.featured(args = {})
      params = {}

      # TODO: Support :offset param
      # TODO: Support :hls param

      limit = args[:limit]
      if limit && (limit < 100)
        params[:limit] = limit
      else
        params[:limit] = 100
        limit = 0
      end

      return connection.accumulate(
        :path => 'streams/featured',
        :params => params,
        :json => 'featured',
        :sub_json => 'stream',
        :class => Stream,
        :limit => limit
      )
    end
  end
end
