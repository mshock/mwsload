#! perl -w

use strict;
use Storable;

my $skip_master = 0;
my $rebuild_master = 1;
# TODO: specify number of card as well
my $quantity_mode = 0;

print "Welcome to the MWS deck clipboard creator!\n";
print "'q' to exit, 'd' to delete previous, 'w' write to file\n";

print "\ndeck name: ";
my $input = <>;
chomp $input;
exit if $input eq 'q';
my $deck_file = "$input.deck";

init_file($deck_file);

my %master;
if (!$skip_master) {
	if ($rebuild_master) {
		print "\n[rebuild] serializing new masterbase file... ";
		open (my $master_fh, '<', 'Master_new.csv');
		while (<$master_fh>) {
			next unless m/^"\S+/;
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
		print "done\n";
	}
	else {
		print "\nloading masterbase for autocompletion... ";
		%master = %{retrieve('masterbase.store')};
		print "done\n";
	}
}
else {
	print "\nskipping masterbase, enter full cardnames (case insensitive)\n";
}

my @output = ("\n");
while(1) {
	print "\ncard name: ";
	$input = <>;
	chomp $input;
	if ($input eq 'q') {
		print "\nsaving and exiting...";
		last;
	}
	elsif ($input eq 'd') {
		my $deleted = pop @output;
		print "\ndeleted previous entry: $deleted\n";
	}
	elsif ($input eq 'w') {
		print "\nwriting cards in memory to deck file... ";
		write_deck(\@output, '>>', $deck_file);
		my $num_cards = scalar @output - 1;
		@output = ("\n");
		print "done\n";
		print "[$num_cards] cards were written\n";
	}
	else {
		if (!$skip_master) {
			if (scalar( split ' ', $input ) > 1 || $input =~ m/\W/) {
				print "\n[masterbase completion mode - enabled]\n";
				print "enter *only* the first word or up to the first non-alpha in the cardname\n";
				next;
			}
		
			if ($master{uc $input}) {
				my @match = sort @{$master{uc $input}};
				if (scalar @match == 1) {
					print "\ncard found: $match[0]\n";
					$input = "1 $match[0]";
				}
				else {
					print "multiple cards found\n";
					for (my $i = 0; $i < scalar @match; $i++) {
						my $cur = $match[$i];
						print "\t$i: $cur\n";
					}
					print "\n";
					until ($input =~ m/^\d+$/ && $input < scalar @match && $input > -1 ) {
						print "[0-${\(scalar @match - 1)}]: ";
						$input = <>;
						chomp $input;
					}
					$input = "1 $match[$input]";
				}
			}
			else {
				print "card not found, try again\n";
				next;
			}
		}
		else {
			$input = "1 $input";
			$input =~ s/ (\w)/' '.uc($1)/ge;
			$input =~ s/(-|\/)(\w)/$1.uc($2)/ge;
			$input =~ s/ (And|The|Of|Into)/' '.lc($1)/ge;
		}
		push @output, $input;
		print "\nadded $input to deck\n";
	}
}
write_deck(\@output, '>>', $deck_file);
print "\ndeck file: $deck_file\n";
print "[${\(scalar @output - 1)}] cards were written\n";


sub init_file { 
	my $deck_file = shift;
	my $input = '';
	if (-f $deck_file) {
		while (1) {
			print "\ndeck file exists - (a)ppend, (o)verwrite, (c)ancel: ";
			$input = <>;
			chomp $input;
			if ($input eq 'a') {
				last;
			}
			elsif ($input eq 'o') {
				print "\nold file will be clobbered, continue? (y/N): ";
				$input = <>;
				chomp $input;
				if ($input =~ m/^y$/i) {
					open (my $deck_fh, '>', $deck_file);
					close $deck_fh;
					last;
				}
			}
			elsif ($input eq 'c') {
				exit;
			}
			else {
				print "error: please select 'a', 'o', or 'c'\n";
			}
		}
	}
}

sub write_deck {
	my ($output_aref, $op, $deck) = @_;
	open (my $deck_fh, $op, $deck);
	print $deck_fh join("\n", @{$output_aref});
	close $deck_fh;
}