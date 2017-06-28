#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Builder;
use Texcon::App;

builder {
  enable 'Plack::Middleware::Static',
    path => qr{^(css|dist|javascripts|scripts) /},
    root => './public/';
  Texcon::App->to_app;
};

