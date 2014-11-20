#require "spec_helper"
require "logstash/outputs/s3"
require 'socket'
require "aws-sdk"
require "fileutils"
require "stud/temporary"

describe LogStash::Outputs::S3, :integration => true do
  let(:minimal_settings)  {  { "access_key_id" => ENV['AWS_ACCESS_KEY_ID'],
                               "secret_access_key" => ENV['AWS_SECRET_ACCESS_KEY'],
                               "bucket" => ENV['AWS_LOGSTASH_TEST_BUCKET'], 
                               "temporary_directory" => Stud::Temporary.pathname('temporary_directory') }}

  describe "#register" do
    it "write a file on the bucket to check permissions" do
      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.register
    end
  end


  describe "#write_on_bucket" do
    after(:all) do
      File.unlink(fake_data.path)
    end

    let!(:fake_data) { Stud::Temporary.file }

    it "should prefix the file on the bucket if a prefix is specified" do
      prefix = "my-prefix"

      config = minimal_settings.merge({
        "prefix" => prefix,
      })

      s3 = LogStash::Outputs::S3.new(config)
      s3.register
      s3.write_on_bucket(fake_data)
    end

    it 'should use the same local filename if no prefix is specified' do
      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.register
      s3.write_on_bucket(fake_data)
    end
  end

  describe "#move_file_to_bucket" do
    let!(:s3) { LogStash::Outputs::S3.new(minimal_settings) }

    before do
      s3.register
    end

    it "should always delete the source file" do
      tmp = Stud::Temporary.file

      allow(File).to receive(:zero?).and_return(true)
      expect(File).to receive(:delete).with(tmp)

      s3.move_file_to_bucket(tmp)
    end

    it 'should not upload the file if the size of the file is zero' do
      temp_file = Stud::Temporary.file
      allow(temp_file).to receive(:zero?).and_return(true)

      expect(s3).not_to receive(:write_on_bucket)
      s3.move_file_to_bucket(temp_file)
    end

    it "should upload the file if the size > 0" do
      tmp = Stud::Temporary.file
      s3.move_file_to_bucket(tmp)
    end
  end

  describe "#restore_from_crashes" do
    it "read the temp directory and upload the matching file to s3" do
      Stud::Temporary.pathname do |temp_path|
        tempfile =   

        s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "temporary_directory" => temp_path }))
        s3.restore_from_crashes
      end
    end
  end
end
