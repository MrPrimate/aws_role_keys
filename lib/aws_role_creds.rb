require "aws_role_creds/version"
require 'aws-sdk'
require 'yaml'
require 'time'
require 'inifile'
require 'fileutils'

module AwsRoleCreds
    
    IN_FILE = "#{ENV['HOME']}/.aws/config.yaml"
    # The config file we write out
    OUT_FILE = ["#{ENV['HOME']}/.aws/config", "#{ENV['HOME']}/.aws/credentials"]
    SESSION_CREDS_FILE = "#{ENV['HOME']}/.aws/session.yaml"
    SESSION_DURATION = 86400
    ROLE_DURATION = 3600
    REGION = 'eu-west-1'

    if File.exists?( IN_FILE )
        @config = YAML::load( File.open( IN_FILE ) )
    else
        puts "Please create a yaml config file in #{INFILE}"
        exit!(1)
    end

    if File.exists?(SESSION_CREDS_FILE)
        @session_credentials = YAML::load( File.open( SESSION_CREDS_FILE ) ) || {}
    else
        @session_credentials = {}
    end

    @role_credentials = {}

    # Get session credentials for each 'master' account
    @config['default'].each do |p|
        name = p['name']
        region = p['region'] || REGION
        duration = p['duration'] || SESSION_DURATION
        if @session_credentials.key?(name)
            break if @session_credentials[name]['expiration'] > Time.now 
        end
        puts "#{name}"
        
        if p['id'] and p['key']
            client = Aws::STS::Client.new(
                access_key_id: p['id'],
                secret_access_key: p['key'],
                region: region
            )
        else
            client = Aws::STS::Client.new(region: region)
        end
        
        if p['mfa_arn']
            puts "Enter MFA token code for #{name} using #{p['mfa_arn']}"
            token = gets
            
            session_credentials = client.get_session_token(
                duration_seconds: duration,
                serial_number: p['mfa_arn'],
                token_code: token.chomp
            )
        else
            session_credentials = client.get_session_token(
                duration_seconds: duration
            )
        end
        
        @session_credentials[name] = {
            'access_key_id' => session_credentials.credentials.access_key_id,
            'secret_access_key' => session_credentials.credentials.secret_access_key,
            'session_token' => session_credentials.credentials.session_token,
            'expiration' => session_credentials.credentials.expiration,
            'region' => region
        }
    end

    # Cache session credentials
    File.open( SESSION_CREDS_FILE, 'w' ) { |f|
        f.write @session_credentials.to_yaml
    }

    # For each role we want to assume grab some assumed credentials using approriate session
    @config['profiles'].each do |p|
        name = p['name']
        default = p['default']
        region =  p['region'] || REGION
        duration = p['duration'] || ROLE_DURATION
        session_credentials = @session_credentials[default]
        puts "Getting credentials for #{name} using #{p['role_arn']}"
        
        client = Aws::STS::Client.new(
            access_key_id: session_credentials['access_key_id'],
            secret_access_key: session_credentials['secret_access_key'],
            session_token: session_credentials['session_token'],
            region: region
        )

        role_credentials = client.assume_role(
            role_arn: p['role_arn'],
            role_session_name: name,
            duration_seconds: duration,
        )
        
        @role_credentials[name] = {
            'role' => p['role_arn'],
            'access_key_id' => role_credentials.credentials.access_key_id,
            'secret_access_key' => role_credentials.credentials.secret_access_key,
            'session_token' => role_credentials.credentials.session_token,
            'expiration' => role_credentials.credentials.expiration,
            'region' => region
        }
    end


    # Write out config file
    # first make a backup
    OUT_FILE.each do |o|
        FileUtils.cp( o, "#{o}.backup" )

        # create a new ini file object
        config = IniFile.new
        config.filename = o

        config['default'] = { "region" => REGION }

        # set properties
        @session_credentials.each do |k, c|
            config["profile #{k}"] = {
                "aws_access_key_id" => "#{c['access_key_id']}",
                "aws_secret_access_key" => "#{c['secret_access_key']}",
                "aws_security_token" => "#{c['session_token']}",
                "region" => "#{c['region']}",
            }
            puts "Profile #{k} created"
        end

        @role_credentials.each do |k, c|
            config["profile #{k}"] = {
                "aws_access_key_id" => "#{c['access_key_id']}",
                "aws_secret_access_key" => "#{c['secret_access_key']}",
                "aws_security_token" => "#{c['session_token']}",
                "region" => "#{c['region']}",
            }
            puts "Profile #{k} created for role #{c['role']}"
        end

        # save file
        config.write()
    end

end
