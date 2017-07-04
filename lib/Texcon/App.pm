package Texcon::App;
use Dancer2;
use Dancer2::Plugin::Email;
use Email::Valid;
use Try::Tiny;
use File::Slurp;

our $VERSION = '0.1';

my $abs_dir = '/users/admin/git/tc.us/public/files';
my $disposables = '/users/admin/git/tc.us/public/disposable_email_blacklist.conf'; #https://raw.githubusercontent.com/martenson/disposable-email-domains/master/disposable_email_blacklist.conf
my $server = 'sg@textileconservation.us';

my $max_attachment = 5242880;
my $max_upload = 20971520;

get '/' => sub {
    template 'index';
};

post '/contact' => sub {
  my $name = param "name";
  my $email = param "email";
  my $body = param "body";
  my $date = localtime;
  my $path;
  my $size = 0;
  my $disposable = 0;
  my ($rel_dir) = $abs_dir =~ /(\/[^\/.]*)$/;
  my @filenames;
  my @paths;
  my @filelisting;
  my @errors;
  my %filenames;

  my @disposables = read_file($disposables, chomp => 1);
  my ($emaildomain) = $email =~ /\@(.*)$/;
  foreach (@disposables) { $disposable = 1 if $emaildomain eq $_ };

  push @errors, "Name is missing." unless $name;
  if ($email) { push @errors, "Email is invalid." unless(Email::Valid->address($email)); }
    else {  push @errors, "Email is missing."; };
  push @errors, "Body of message is missing." unless $body;
  push @errors, "Email is disposable. Please enter a permanent one." if $disposable == 1;

  if (@errors) {
    my $error = join("</p><p>",@errors,"Please return to the form and correct it.");
    return template 'error', { title => 'error', content => $error };
  };

  my @data = request->upload('files');
  if (@data) {
    foreach my $data (@data) {
      my ($ext) = $data->basename =~ /(\.[^.]{2,4})$/;
      my $filename = substr(rand(),2).$ext;
      my $path = path($abs_dir, $filename);
      if (-e $path) {
  	return template 'error', { title => 'error', content => 'an unlikely error occurred...please return to the form and resubmit' };
      };
      $data->link_to($path);
      push @filenames, $filename;
      push @paths, $path;
      $filenames{$filename} = $data->basename;
      $size += -s $path;
      if ($size > $max_upload) {
	map { unlink $_ } @paths;
  	return template 'error', { title => 'cancelled', content => 'file upload is too large' };
      };
    };

    @filelisting = map { "<li><a href=\"" . uri_for($rel_dir) . '/' . $_ . "\">$filenames{$_}</a></li>\n<p></p>" } @filenames;
    unshift @filelisting, "<p>Attachments:</p>\n<dl>\n";
    push @filelisting, "</dl>\n";
  };

  @paths = () unless $size < $max_attachment;

  $body = "<p>From $name <$email></p><p>Submitted $date</p><p>$body</p><p>@filelisting</p>";

  try {
    email {
      from    => "$name <$email>",
      to      => "$server",
      subject => 'textileconservation form submission',
      body    => "$body",
      multipart => 'related',
      attach  => [ @paths ],
      type    => 'html',
    };
  } catch {
      return template 'error', { title => 'error', content => "could not send email: $_" };
  };

  $body = "<p>Your inquiry was received $date.</p><p>The studio will review it and contact you as soon as possible.</p><p>Thank you,<br>sg\@textileconservation.us<br>";

  try {
    email {
      from    => "$server",
      to      => "$name <$email>",
      subject => 'inquiry acknowledgement',
      body    => "$body",
      type    => 'html',
    };
  } catch {
      return template 'error', { title => 'error', content => "could not send email: $_" };
  };
  redirect '/complete';
};

any qr{.+\/$} => sub {
  redirect '/';
};

true;
