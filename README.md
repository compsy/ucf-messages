# UCF Messages

A gem for retrieving the invitation text to send for the [u-can-feel](https://u-can-feel.nl) project.

### Building

```bash
% gem build ucf_messages.gemspec
% gem install ./ucf_messages-0.0.1.gem
```

### Running

```bash
% irb
>> require 'ucf_messages'
=> true
>> UcfMessages.hi
Hello world!
```

### Publishing
See https://guides.rubygems.org/make-your-own-gem/ for setting credentials.

```bash
% gem push ucf_messages-0.0.1.gem
```
