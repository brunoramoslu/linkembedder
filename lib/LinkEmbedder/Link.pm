package LinkEmbedder::Link;
use Mojo::Base -base;

use Mojo::Template;
use Mojo::Util 'trim';

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

my %DOM_SEL = (
  ':desc'      => ['meta[property="og:description"]', 'meta[name="twitter:description"]', 'meta[name="description"]'],
  ':image'     => ['meta[property="og:image"]',       'meta[property="og:image:url"]',    'meta[name="twitter:image"]'],
  ':site_name' => ['meta[property="og:site_name"]',   'meta[property="twitter:site"]'],
  ':title'     => ['meta[property="og:title"]',       'meta[name="twitter:title"]',       'title'],
);

my @JSON_ATTRS = (
  'author_name',      'author_url',    'cache_age',       'height', 'provider_name', 'provider_url',
  'thumbnail_height', 'thumbnail_url', 'thumbnail_width', 'title',  'type',          'url',
  'version',          'width'
);

has author_name => undef;
has author_url  => undef;
has cache_age   => 0;
has description => '';
has error       => undef;                                                # {message => "", code => ""}
has height      => sub { $_[0]->type =~ /^photo|video$/ ? 0 : undef };

has placeholder_url => sub {
  return sprintf 'http://placehold.it/200x200?text=%s', shift->provider_name;
};

has provider_name => sub {
  return undef unless my $name = shift->url->host;
  return $name =~ /([^\.]+)\.(\w+)$/ ? ucfirst $1 : $name;
};

has provider_url => sub { $_[0]->url->host ? $_[0]->url->clone->path('/') : undef };
has template => sub { [__PACKAGE__, sprintf '%s.html.ep', $_[0]->type] };
has thumbnail_height => undef;
has thumbnail_url    => undef;
has thumbnail_width  => undef;
has title            => undef;
has type             => 'link';
has ua               => undef;                                                # Mojo::UserAgent object
has url              => undef;                                                # Mojo::URL
has version          => '1.0';
has width            => sub { $_[0]->type =~ /^photo|video$/ ? 0 : undef };

sub html {
  my $self     = shift;
  my $template = Mojo::Loader::data_section(@{$self->template}) or return '';
  my $output   = Mojo::Template->new({auto_escape => 1, prepend => 'my $l=shift'})->render($template, $self);
  die $output if ref $output;
  return $output;
}

sub learn {
  my ($self, $cb) = @_;
  my $url = $self->url;

  if ($cb) {
    $self->ua->get($url => sub { $self->tap(_learn => $_[1])->$cb });
  }
  else {
    $self->_learn($self->ua->get($url));
  }

  return $self;
}

sub TO_JSON {
  my $self = shift;
  my %json;

  for my $attr (grep { defined $self->$_ } @JSON_ATTRS) {
    $json{$attr} = $self->$attr;
    $json{$attr} = "$json{$attr}" if $attr =~ /url$/;
  }

  $json{html} = $self->html unless $self->type eq 'link';

  return \%json;
}

sub _dump { Mojo::Util::dumper($_[0]->TO_JSON); }

sub _el {
  my ($self, $dom, @sel) = @_;
  @sel = @{$DOM_SEL{$sel[0]}} if $DOM_SEL{$sel[0]};

  for (@sel) {
    my $e = $dom->at($_) or next;
    my $val = trim($e->{content} || $e->{value} || $e->{href} || $e->text || '') or next;
    return $val;
  }
}

sub _learn {
  my ($self, $tx) = @_;
  my $ct = $tx->res->headers->content_type || '';

  $self->type('photo')->_learn_from_url               if $ct =~ m!^image/!;
  $self->type('video')->_learn_from_url               if $ct =~ m!^video/!;
  $self->type('rich')->_learn_from_url                if $ct =~ m!^text/plain!;
  $self->type('rich')->_learn_from_dom($tx->res->dom) if $ct =~ m!^text/html!;

  return $self;
}

sub _learn_from_dom {
  my ($self, $dom) = @_;
  my $v;

  $self->author_name($v)      if $v = $self->_el($dom, '[itemprop="author"] [itemprop="name"]');
  $self->author_url($v)       if $v = $self->_el($dom, '[itemprop="author"] [itemprop="email"]');
  $self->description($v)      if $v = $self->_el($dom, ':desc');
  $self->provider_name($v)    if $v = $self->_el($dom, ':site_name');
  $self->thumbnail_height($v) if $v = $self->_el($dom, 'meta[property="og:image:height"]');
  $self->thumbnail_url($v)    if $v = $self->_el($dom, ':image');
  $self->thumbnail_width($v)  if $v = $self->_el($dom, 'meta[property="og:image:width"]');
  $self->title($v)            if $v = $self->_el($dom, ':title');
}

sub _learn_from_json {
  my ($self, $tx) = @_;
  my $json = $tx->res->json;

  warn "[LinkEmbedder] " . $tx->res->text . "\n" if DEBUG;
  $self->{$_} ||= $json->{$_} for keys %$json;
  $self->{error} = {message => $self->{error}} if defined $self->{error} and !ref $self->{error};
  $self->{error}{code} = $self->{status} if $self->{status} and $self->{status} =~ /^\d+$/;
}

sub _learn_from_url {
  my $self = shift;
  my $path = $self->url->path;

  $self->title(@$path ? $path->[-1] : 'Image');
  $self;
}

1;

=encoding utf8

=head1 NAME

LinkEmbedder::Link - Meta information for an URL

=head1 SYNOPSIS

See L<LinkEmbedder>.

=head1 DESCRIPTION

L<LinkEmbedder::Link> is a class representing an expanded URL.

=head1 ATTRIBUTES

=head2 author_name

  $str = $self->author_name;

Might hold the name of the author of L</url>.

=head2 author_url

  $str = $self->author_name;

Might hold an URL to the author.

=head2 cache_age

  $int = $self->cache_age;

The suggested cache lifetime for this resource, in seconds.

=head2 description

  $str = $self->description;

Description of the L</url>. Might be C<undef()>.

=head2 error

  $hash_ref = $self->author_name;

C<undef()> on success, hash-ref on error. Example:

  {message => "Oops!", code => 500};

=head2 height

  $int = $self->height;

The height of L</html> in pixels. Might be C<undef>.

=head2 provider_name

  $str = $self->provider_name;

Name of the provider of L</url>.

=head2 provider_url

  $str = $self->provider_name;

Main URL to the provider's home page.

=head2 template

  $array_ref = $self->provider_name;

Used to figure out which template to use to render L</html>. Example:

  ["LinkEmbedder::Link", "rich.html.ep];

=head2 thumbnail_height

  $int = $self->thumbnail_height;

The height of the L</thumbnail_url> in pixels. Might be C<undef>.

=head2 thumbnail_url

  $str = $self->thumbnail_url;

URL to the thumbnail which can be used in L</html>.

=head2 thumbnail_width

  $int = $self->thumbnail_width;

The width of the L</thumbnail_url> in pixels. Might be C<undef>.

=head2 title

  $str = $self->title;

Title/heading of the L</url>. Might be C<undef()>.

=head2 type

  $str = $self->title;

oEmbed type of URL: link, photo, rich or video.

=head2 ua

  $ua = $self->ua;

Holds a L<Mojo::UserAgent> object.

=head2 url

  $str = $self->url;

The resource to fetch.

=head2 version

  $str = $self->version;

oEmbed version. Example: "1.0".

=head2 width

  $int = $self->width;

The width in pixels. Might be C<undef>.

=head1 METHODS

=head2 html

  $str = $self->html;

Returns the L</url> as rich markup, if possible.

=head2 learn

  $self = $self->learn;
  $self = $self->learn(sub { my $self = shift; });

Used to learn about the L</url>.

=head1 AUTHOR

Jan Henning Thorsen

=head1 SEE ALSO

L<LinkEmbedder>

=cut

__DATA__
@@ iframe.html.ep
<iframe class="le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>" width="<%= $l->width || 600 %>" height="<%= $l->height || 400 %>" style="border:0;width:100%" frameborder="0" allowfullscreen src="<%= $l->{iframe_src} %>"></iframe>
@@ link.html.ep
<a class="le-<%= $l->type %>" href="<%= $l->url %>" title="<%= $l->title || '' %>"><%= Mojo::Util::url_unescape($l->url) %></a>
@@ paste.html.ep
<div class="le-paste le-provider-<%= lc $l->provider_name %> le-<%= $l->type %>">
  <div class="le-meta">
    <span class="le-provider-link"><a href="<%= $l->provider_url %>"><%= $l->provider_name %></a></span>
    <span class="le-goto-link"><a href="<%= $l->url %>" title="<%= $l->title %>"><%= $l->{paste_name} || $l->author_name || 'View' %></a></span>
  </div>
  <pre><%= $l->{paste} || '' %></pre>
</div>
@@ photo.html.ep
<div class="le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>">
  <img src="<%= $l->url %>" alt="<%= $l->title %>">
</div>
@@ rich.html.ep
% if ($l->title) {
  % if (my $thumbnail_url = $l->thumbnail_url || $l->placeholder_url) {
<div class="le-card le-image-card le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>">
    <a href="<%= $l->url %>" class="le-thumbnail<%= $l->thumbnail_url ? '' : '-placeholder' %>">
      <img src="<%= $thumbnail_url %>" alt="<%= $l->author_name || 'Placeholder' %>">
    </a>
  % } else {
<div class="le-card le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>">
  % }
  <h3><%= $l->title %></h3>
    % if ($l->description) {
  <p class="le-description"><%= $l->description %></p>
    % }
  <div class="le-meta">
    % if ($l->author_name) {
    <span class="le-author-link"><a href="<%= $l->author_url || $l->url %>"><%= $l->author_name %></a></span>
    % }
    <span class="le-goto-link"><a href="<%= $l->url %>"><span><%= $l->url %></span></a></span>
  </div>
</div>
% } else {
<a class="le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>" href="<%= $l->url %>"><%= Mojo::Util::url_unescape($l->url) %></a>
% }
@@ video.html.ep
<video class="le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>" height="640" width="480" preload="metadata" controls>
% for my $s (@{$l->{sources} || []}) {
  <source src="<%= $s->{url} %>" type="<%= $s->{type} || '' %>">
% }
  <p>Your browser does not support the video tag.</p>
</video>
