#! perl -w

use strict;
use feature 'say';
use Storable;
use Getopt::Long;
#use Tk;

my ($skip_master, $rebuild_master, $quantity_mode );
GetOptions( 's|skip' => \$skip_master,
			'r|rebuild' => \$rebuild_master
		  );

main();


sub main {
	say "Welcome to the MWS deck clipboard creator!";
	
	my $deck_file = ${init_deck()};
	
	my %master;
	if (!$skip_master) {
		%master = %{masterbase($rebuild_master)};
	}
	else {
		say "\nskipping masterbase, enter full cardnames (case insensitive)";
	}
	
	
	my $quant = 1;
	my $num_cards = 0;
	my @output = ("\n");
	my %opts_hash = (
		d => sub {
				my ($num, $card) = pop(@output) =~ m/(\d+)\s+(.+)/;
				say "\ndeleted previous entry: x$num $card";
				$num_cards -= $num;
				goto LOAD;
			},
		w => sub {
				print "\nwriting cards in memory to deck file... ";
				write_deck(\@output, '>>', $deck_file);
				@output = ("\n");
				say 'done';
				say "[$num_cards] card(s) written";
				$num_cards = 0;
				goto LOAD;
			},
		q => sub {
				goto SAVEQUIT;
			},
	);
	
	while(1) {
		LOAD:
		my $tmp_quant = undef;
		my $input = '';
		print "\ncard name: ";
		$input = input();
		check4opt($input, \%opts_hash);
		
		if ($input =~ m/^(\d+)$/) {
			$quant = $1;
			say "default card quantity set : x$quant";
			goto LOAD;
		}
		
		
		if (!$skip_master) {
			if ($input =~ m/\d\D+|\W/) {
				say "\n[masterbase completion mode is enabled]";
				say "enter *only* the first word or up to the first non-alpha in the cardname";
				next;
			}
			elsif ($input =~ m/^([a-zA-Z]+)(\d+)$/) {
				$input = $1;
				$tmp_quant = $2;
				say "$input x$tmp_quant";
			}
			
			
			if ($master{uc $input}) {
				my $local_quant = defined $tmp_quant ? $tmp_quant : $quant;
				my @match = sort @{$master{uc $input}};
				if (scalar @match == 1) {
					say "\ncard found: $match[0]";
					$input = "$local_quant $match[0]";
				}
				else {
					say "multiple cards found";
					for (my $i = 0; $i < scalar @match; $i++) {
						my $cur = $match[$i];
						say "\t$i: $cur";
					}
					until ($input =~ m/^\d+$/ && $input < scalar @match && $input > -1 ) {
						print "\n[0-${\(scalar @match - 1)}]: ";
						$input = input();
					}
					$input = "$local_quant $match[$input]";
					$num_cards  += $local_quant;
				}
			}
			else {
				say "card not found, try again";
				next;
			}
		}
		else {
			if ($input =~ m/^(\D+)(\d+)$/) {
				$input = $1;
				$tmp_quant = $2;
				say "$input x$tmp_quant";
				$num_cards += $tmp_quant;
			}
			
			$input = sprintf("%u $input", defined $tmp_quant ? $tmp_quant : $quant);
			$input =~ s/ (\w)/' '.uc($1)/ge;
			$input =~ s/(-|\/)(\w)/$1.uc($2)/ge;
			$input =~ s/ (And|The|Of|Into)/' '.lc($1)/ge;
		}
		push @output, $input;
		say "\nadded $input to deck";
	}
	SAVEQUIT:
	print "\nsaving and exiting...";
	write_deck(\@output, '>>', $deck_file);
	say "\ndeck file: $deck_file";
	say "[$num_cards] card(s) written";
}

sub masterbase {
	my $rebuild_master = shift;
	my %master;
	if ($rebuild_master) {
		print "\n[rebuild] serializing new masterbase file... ";
		open (my $master_fh, '<', 'Master_new.csv');
		while (<$master_fh>) {
			next unless m/^"\S+/;
			# TODO: load extra fields for... something
			#chomp;
			#my ($name, $edition, $rarity, $color, $cost, $PT, $type, $text, $flavor) = split "\t", $_;
			my ($name) = split ';', $_;
			$name =~ s/"//g;
			$name =~ s/\s*\(\d+\)\s*//;
			my ($tag) = $name =~ m/^(\w+)/;
			$tag = uc $tag;
			if ($master{$tag}) {
				my @collisions = @{$master{$tag}};
				my $found = 0;
				for my $entry (@collisions) {
					if ($entry eq $name) {
						$found = 1;
						last;
					}
				}
				if ($found) {
					next;
				}
			}
			push @{$master{$tag}}, $name;
		}
		close $master_fh;
		store \%master, 'masterbase.store';
		say 'done';
	}
	else {
		print "\nloading masterbase for autocompletion... ";
		%master = %{retrieve('masterbase.store')};
		say 'done';
	}
	return \%master;
}

sub input {
	my $input = <>;
	chomp $input;
	return $input;
}

sub check4opt {
	my ($input, $opts_href) = @_;
	return $input if length($input) != 1;
	exit if $input =~ m/Q|c/;
	
	$opts_href->{$input}->() 
			if defined $opts_href->{$input} && ref $opts_href->{$input} eq 'CODE';
		
}

sub init_deck {
	say "'Q' to exit, 'd' to delete previous, 'w' write to file";
	print "\ndeck name: ";
	my $deck_file = check4opt(input()) . '.deck';
	init_file($deck_file);
	return \$deck_file;
}

sub init_file {
	my $deck_file = shift;
	my $input = '';
	if (-f $deck_file) {
		my %opts_hash = (
			a =>	sub { say "\nappending to existing deck file"; goto DECKDONE },		
			o =>	sub { 
						print "\nold file will be clobbered, continue? (y/N): ";
						$input = input();
						if ($input =~ m/^y$/i) {
							open (my $deck_fh, '>', $deck_file);
							close $deck_fh;
							goto DECKDONE
						}
					},
			'default' => sub { say "error: please select 'a', 'o', or 'c'" },
		);
		while (1) {
			print "\ndeck file exists - (a)ppend, (o)verwrite, (c)ancel: ";
			$input = check4opt(input(), \%opts_hash);	
		}
		DECKDONE:
	}
}

sub write_deck {
	my ($output_aref, $op, $deck) = @_;
	open (my $deck_fh, $op, $deck);
	print $deck_fh join("\n", @{$output_aref});
	close $deck_fh;
}