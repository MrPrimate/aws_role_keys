# AwsRoleCreds

Have several AWS accounts that you access through delegation? Want a id/key combo for each one? Need to use MFA? But want to use the cli?

It can get frustrating managing so many accounts. If you have one (or even more) 'master' account that you assume roles in other accounts then this script will handle generating profiles and temporary session credentials, and keeping your MFA logins to a minimum.

## Installation

Install with

    $ gem install aws_role_creds

## Usage

Create a YAML file to manage your profiles, and MFA device, at `~/.aws/config.yaml`

```
---
default:
  - name:
    id:
    key:
    mfa_arn: (optional)
    region: (optional)
profiles:
  - name:
    role_arn:
    region: (optional)
    default: default profile to use
```

Run `aws_role_creds` and it will get credentials for your default accounts. It will then use these credentials to Assume Roles and get credentials for each of your profiles. 

Default accounts get creds lasting 24 hours, and assumed role profiles can last an hour. If your credentials expire, run the script again and it will refresh them. It will only ask for you MFA if it is required, i.e. your session credentials have expired.

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MrPrimate/aws_role_creds.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
