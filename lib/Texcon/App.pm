package Texcon::App;
use Dancer2;
use Dancer2::Plugin::Email;
use Email::Valid;
use Try::Tiny;
use File::Slurp;
use Template;

our $VERSION = '0.1';

my $base_dir = '/var/www/textileconservation.us';
my $upload_dir = "$base_dir/public/files";
my $server = 'sg@textileconservation.us';
my $disposables = "$base_dir/public/disposable_email_blocklist.conf";
#mail template
my $mail_template = Template->new({ INCLUDE_PATH => "$base_dir/views", INTERPOLATE  => 1, }) || die Template->error(),"\n";

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
  my ($rel_upload_dir) = $upload_dir =~ /(\/[^\/.]*)$/;
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
      my $path = path($upload_dir, $filename);
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
  };

  @paths = () unless $size < $max_attachment;

  my $mail_vars = {
	      rel_uri => uri_for($rel_upload_dir),
	      date => $date,
	      email => $email,
	      body => $body,
	      server => $server,
	      filelist => \@filenames,
	      filenames => \%filenames,
  };
  my $mail_body;
  
  $mail_template->process('mail_body.tt', $mail_vars, \$mail_body) || die $mail_template->error();

  try {
    email {
      from    => "$name <$email>",
      to      => "$server",
      subject => 'textileconservation form submission',
      body    => "$mail_body",
      multipart => 'related',
      attach  => [ @paths ],
      type    => 'html',
    };
  } catch {
      return template 'error', { title => 'error', content => "could not send email: $_" };
  };

  my $mail_ack;
  
  $mail_template->process('mail_ack.tt', $mail_vars, \$mail_ack) || die $mail_template->error();

  try {
    email {
      from    => "$server",
      to      => "$name <$email>",
      subject => 'inquiry acknowledgement',
      body    => "$mail_ack",
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
