require 'time'
require 'openssl'
require 'base64'

class S3UrlGenerator
  attr_reader :url, :headers

  def initialize(bucket,path,aws_access_key_id,aws_secret_access_key)
    now = Time.now().utc.strftime('%a, %d %b %Y %H:%M:%S GMT')
    string_to_sign = "GET\n\n\n%s\n/%s%s" % [now,bucket,path]

    digest = digest = OpenSSL::Digest::Digest.new('sha1')
    signed = OpenSSL::HMAC.digest(digest, aws_secret_access_key, string_to_sign)
    signed_base64 = Base64.encode64(signed)

    auth_string = 'AWS %s:%s' % [aws_access_key_id,signed_base64]

    @url = 'https://%s.s3.amazonaws.com%s' % [bucket,path]
    @headers = { 'date' => now, 'authorization' => auth_string }
  end
end
