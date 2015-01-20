package Mojolicious::Plugin::LinkEmbedder::Link::Video::AppearIn;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Video::AppearIn - vimeo.com video

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Video>.

=cut

use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Video';

=head1 ATTRIBUTES

=head2 media_id

Returns the room name from the url L</url>.

=head2 provider_name

=cut

has media_id => sub {
  my $self = shift;

  return '' if defined $self->url->path->[1];
  return $self->url->path->[0] || '';
};

sub provider_name {'appear.in'}

=head1 METHODS

=head2 learn

=cut

sub learn {
  my ($self, $c, $cb) = @_;

  return $self->$cb if $self->media_id;
  return $self->SUPER::learn($c, $cb);
}

=head2 to_embed

Returns the HTML code for an iframe embedding this movie.

=cut

sub to_embed {
  my $self     = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;
  my %args     = @_;

  $self->_iframe(
    src    => "https://appear.in/$media_id",
    class  => 'link-embedder video-appearin',
    width  => $args{width} || 740,
    height => $args{height} || 390
  );
}

=head1 AUTHOR

Marcus Ramberg

=cut

1;
