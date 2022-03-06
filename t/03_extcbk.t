use 5.008001;

use strict;
use warnings;
use Test::More;
use Text::Balanced qw ( extract_codeblock );

our $DEBUG;
sub debug { print "\t>>>",@_ if $DEBUG }

## no critic (BuiltinFunctions::ProhibitStringyEval)

my $cmd = "print";
my $neg = 0;
my $str;
while (defined($str = <DATA>))
{
    chomp $str;
    if ($str =~ s/\A# USING://) { $neg = 0; $cmd = $str; next; }
    elsif ($str =~ /\A# TH[EI]SE? SHOULD FAIL/) { $neg = 1; next; }
    elsif (!$str || $str =~ /\A#/) { $neg = 0; next }
    $str =~ s/\\n/\n/g;
    debug "\tUsing: $cmd\n";
    debug "\t   on: [$str]\n";

    my @res;
    my $var = eval "\@res = $cmd";
    is $@, '', 'no error';
    debug "\t list got: [" . join("|", map {defined $_ ? $_ : '<undef>'} @res) . "]\n";
    debug "\t list left: [$str]\n";
    ($neg ? \&isnt : \&is)->(substr($str,pos($str)||0,1), ';');

    pos $str = 0;
    $var = eval $cmd;
    is $@, '', 'no error';
    $var = "<undef>" unless defined $var;
    debug "\t scalar got: [$var]\n";
    debug "\t scalar left: [$str]\n";
    ($neg ? \&unlike : \&like)->( $str, qr/\A;/);
}

done_testing;

__DATA__

# USING: extract_codeblock($str,'(){}',undef,'()');
(Foo(')'));

# USING: extract_codeblock($str);
{ $data[4] =~ /['"]/; };

# USING: extract_codeblock($str,'<>');
< %x = ( try => "this") >;
< %x = () >;
< %x = ( $try->{this}, "too") >;
< %'x = ( $try->{this}, "too") >;
< %'x'y = ( $try->{this}, "too") >;
< %::x::y = ( $try->{this}, "too") >;

# THIS SHOULD FAIL
< %x = do { $try > 10 } >;

# USING: extract_codeblock($str);

{ $a = /\}/; };
{ sub { $_[0] /= $_[1] } };  # / here
{ 1; };
{ $a = 1; };


# USING: extract_codeblock($str,undef,'=*');
========{$a=1};

# USING: extract_codeblock($str,'{}<>');
< %x = do { $try > 10 } >;

# USING: extract_codeblock($str,'{}',undef,'<>');
< %x = do { $try > 10 } >;

# USING: extract_codeblock($str,'{}');
{ $a = $b; # what's this doing here? \n };'
{ $a = $b; \n $a =~ /$b/; \n @a = map /\s/ @b };

# THIS SHOULD FAIL
{ $a = $b; # what's this doing here? };'
{ $a = $b; # what's this doing here? ;'
