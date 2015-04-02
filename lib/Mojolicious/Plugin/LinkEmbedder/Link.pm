package Mojolicious::Plugin::LinkEmbedder::Link;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link - Base class for links

=cut

use Mojo::Base -base;
use Mojo::ByteStream;
use Mojo::Util 'xml_escape';
use Mojolicious::Types;
use Scalar::Util 'blessed';

# this may change in future version
use constant DEFAULT_VIDEO_HEIGHT => 390;
use constant DEFAULT_VIDEO_WIDTH  => 640;

=head1 ATTRIBUTES

=head2 error

  my $err = $link->error;
  $link   = $link->error({message => "Some error"});

Get or set error. Default to C<undef> on no error.

=head2 etag

=head2 media_id

Returns the part of the URL identifying the media. Default is empty string.

=head2 provider_name

  $str = $self->provider_name;

Example: "Twitter".

=head2 ua

Holds a L<Mojo::UserAgent> object.

=head2 url

Holds a L<Mojo::URL> object.

=cut

has error => undef;
has etag  => sub {
  eval { shift->_tx->res->headers->etag } // '';
};
has media_id => '';
sub provider_name { ucfirst(shift->url->host || '') }
has ua  => sub { die "Required in constructor" };
has url => sub { shift->_tx->req->url };

# should this be public?
has _tx => undef;

has _types => sub {
  my $types = Mojolicious::Types->new;
  $types->type(mpg  => 'video/mpeg');
  $types->type(mpeg => 'video/mpeg');
  $types->type(mov  => 'video/quicktime');
  $types;
};

=head1 METHODS

=head2 is

  $bool = $self->is($str);
  $bool = $self->is('video');
  $bool = $self->is('video-youtube');

Convertes C<$str> using L<Mojo::Util/camelize> and checks if C<$self>
is of that type:

  $self->isa('Mojolicious::Plugin::LinkEmbedder::Link::' .Mojo::Util::camelize($_[1]));

=cut

sub is {
  $_[0]->isa(__PACKAGE__ . '::' . Mojo::Util::camelize($_[1]));
}

=head2 learn

  $self->learn($c, $cb);

This method can be used to learn more information about the link. This class
has no idea what to learn, so it simply calls the callback (C<$cb>) with
C<@cb_args>.

=cut

sub learn {
  my ($self, $c, $cb) = @_;
  $self->$cb;
  $self;
}

=head2 pretty_url

Returns a pretty version of the L</url>. The default is to return a cloned
version of L</url>.

=cut

sub pretty_url { shift->url->clone }

=head2 tag

  $bytestream = $self->tag(a => href => "http://google.com", sub { "link });

Same as L<https://metacpan.org/pod/Mojolicious::Plugin::TagHelpers#tag>.

=cut

sub tag {
  my $self = shift;
  my $name = shift;

  # Content
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my $content = @_ % 2 ? pop : undef;

  # Start tag
  my $tag = "<$name";

  # Attributes
  my %attrs = @_;
  if ($attrs{data} && ref $attrs{data} eq 'HASH') {
    while (my ($key, $value) = each %{$attrs{data}}) {
      $key =~ y/_/-/;
      $attrs{lc("data-$key")} = $value;
    }
    delete $attrs{data};
  }

  for my $k (sort keys %attrs) {
    $tag .= defined $attrs{$k} ? qq{ $k="} . xml_escape($attrs{$k} // '') . '"' : " $k";
  }

  # Empty element
  unless ($cb || defined $content) { $tag .= '>' }

  # End tag
  else { $tag .= '>' . ($cb ? $cb->() : xml_escape $content) . "</$name>" }

  # Prevent escaping
  return Mojo::ByteStream->new($tag);
}

=head2 to_embed

Returns a link to the L</url>, with target "_blank".

=cut

sub to_embed {
  my $self = shift;
  my $url  = $self->url;
  my @args;

  return sprintf '<a href="#">%s</a>', $self->provider_name unless $url->host;

  push @args, target => '_blank';
  push @args, title => "Content-Type: @{[$self->_tx->res->headers->content_type]}" if $self->_tx;

  return $self->tag(a => (href => $url, @args), sub {$url});
}

# Mojo::JSON will automatically filter out ua and similar objects
sub TO_JSON {
  my $self = shift;
  my $url  = $self->url;

  return {
    # oembed
    # author_name => "",
    # author_url => "",
    # cache_age => 86400,
    # height => $self->DEFAULT_VIDEO_HEIGHT,
    # version => '1.0', # not really 1.0...
    # width => $self->DEFAULT_VIDEO_WIDTH,
    html          => $self->to_embed,
    provider_name => $self->provider_name,
    provider_url  => $url->host ? Mojo::URL->new(host => $url->host, scheme => $url->scheme || 'http') : '',
    type          => 'rich',
    url           => $url,

    # extra
    pretty_url => $self->pretty_url,
    media_id   => $self->media_id,
  };
}

sub _iframe {
  shift->tag(
    iframe                => frameborder => 0,
    allowfullscreen       => undef,
    webkitAllowFullScreen => undef,
    mozallowfullscreen    => undef,
    scrolling             => 'no',
    class                 => 'link-embedder',
    @_, 'Your browser is super old.',
  );
}

=head1 AUTHOR

Jan Henning Thorsen - C<jan.henning@thorsen.pm>

=cut

1;
