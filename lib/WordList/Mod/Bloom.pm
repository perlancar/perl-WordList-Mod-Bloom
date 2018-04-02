package WordList::Mod::Bloom;

# DATE
# VERSION

our @patches = (
    ['word_exists', 'replace', sub {
         require MIME::Base64;

         my $ctx = shift;

         my ($self, $word) = @_;

         my $pkg = ref($self);
         my $bloom = ${"$pkg\::BLOOM_FILTER"};

         unless ($bloom) {
             (my $wl_subpkg = $pkg) =~ s/\AWordList:://;
             my $bloom_pkg = "WordList::Bloom::$wl_subpkg";
             (my $bloom_pkg_pm = "$bloom_pkg.pm") =~ s!::!/!g;
             require $bloom_pkg_pm;

             my $fh = \*{"$bloom_pkg\::DATA"};
             my $bloom_str = do {
                 local $/;
                 MIME::Base64::decode_base64(<$fh>);
             };

             require Algorithm::BloomFilter;
             ${"$pkg\::BLOOM_FILTER"} = $bloom =
                 Algorithm::BloomFilter->deserialize($bloom_str);
         }

         $bloom->test($word);
     }],
);

1;
# ABSTRACT: Provide word_exists() that uses bloom filter

=head1 SYNOPSIS

In your F<WordList/EN/Foo.pm>:

 package WordList::EN::Foo;

 __DATA__
 word1
 word2
 ...

In your F<WordList/Bloom/EN/Foo.pm>:

 package WordList::Bloom::EN::Foo;
 1;
 __DATA__
 (The actual bloom filter, base64-encoded)

Then:

 use WordList::Mod qw(mod_wordlist);
 my $wl = mod_wordlist("EN::Foo", "Bloom");

 $wl->word_exists("foo"); # uses bloom filter to check for existence.


=head1 DESCRIPTION

EXPERIMENTAL.

This mod provides an alternative C<word_exists()> method that checks a bloom
filter located in the data section of C<<
WordList::Bloom::<Your_WordList_Subpackage> >>. This provides a low
startup-overhead way to check an item against a big list (e.g. millions). Note
that testing using a bloom filter can result in a false positive (i.e.
C<word_exists()> returns true but the word is not actually in the list.


=head1 SEE ALSO
