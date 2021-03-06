#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use Data::Dumper;
use FindBin        qw($Bin $Script);
use File::Basename qw(basename dirname);
use Cwd            'abs_path';

my $BEGIN_TIME=time();

# ------------------------------------------------------------------
my ($gtf, $genome, $cuffnorm, $cufflinks, $od, $index, $step);
GetOptions(
				"help|?"      =>\&USAGE,
				"gtf:s"       =>\$gtf,
				"genome:s"    =>\$genome,
				"cuffnorm:s"  =>\$cuffnorm,
				"cufflinks:s" =>\$cufflinks,
				"od:s"        =>\$od,
				"index:s"     =>\$index,
				"s:s"         =>\$step,
				) or &USAGE;
&USAGE unless ($gtf and ( $cuffnorm and $cufflinks) and $index) ;
################################
my $notename=`hostname`;chomp $notename;

$gtf = abs_path($gtf);
$od ||= "./";            mkdir $od unless (-d $od); 
$od  = abs_path($od);

my $log_dir      = "$od/track_list_log";     mkdir $log_dir      unless (-d $log_dir);
my $track_dir    = "$od/final_track";        mkdir $track_dir    unless (-d $track_dir);
#my $new_gene_dir = "$od/new_gene";           mkdir $new_gene_dir unless (-d $new_gene_dir);
my $old_gene_dir = "$od/old_gene";           mkdir $old_gene_dir unless (-d $old_gene_dir);
my $sh_dir       = "$od/work_sh";            mkdir $sh_dir       unless (-d $sh_dir);

$step = $step || 1;
####################################### Make info for the program
if ($step==1) {
	open OUT,">$od/work_sh/Step1.sh" || die $!;
	print OUT "cd $od/track_list_log && perl $Bin/bin/track2name.pl $gtf $index\n";
	close OUT;
	system "sh $od/work_sh/Step1.sh";
	$step = 2;
}

if ($step==2) {
	open OUT,">$od/work_sh/Step2.sh" || die $!;
	print OUT "cd $od/track_list_log && perl $Bin/bin/Track2name_format.pl $index $index\n";
	close OUT;
	system "sh $od/work_sh/Step2.sh";
	$step = 5;
}

# if ($step == 3) {
# 	open OUT,">$od/work_sh/Step3.sh" || die $!;
# 	print OUT "cd $od/track_list_log && perl $Bin/bin/newGene_format.pl $gtf $index $od/final_track\n";
# 	close OUT;
# 	system "sh $od/work_sh/Step3.sh";
# 	$step = 4;
# }

=pod
if ($step == 4) {
	open OUT,">$od/work_sh/Step4.sh" || die $!;
	print OUT "cd $od/track_list_log && perl $Bin/bin/final_track_info.pl $gtf $index $od/final_track\n ";
	#print OUT "perl $Bin/bin/filter.new_gene.pl $index $genome $od/final_track\n";
	close OUT;
	system "sh $od/work_sh/Step4.sh";
	$step = 5;
}
=cut
if ($step == 5 && defined $cuffnorm) {
	open OUT,">$od/work_sh/Step5_cuffnorm.sh" || die $!;
	print OUT "perl $Bin/bin/list2expression.pl $od/final_track/$index.final_tracking.list $cuffnorm $od/old_gene\n";
	# print OUT "perl $Bin/bin/list2expression.pl $od/final_track/$index.newGene_filtered_final_tracking.list $cuffnorm $od/new_gene\n";
	close OUT;
	system "sh $od/work_sh/Step5_cuffnorm.sh";
	$step = 6;
}


#if ($step == 6 && defined $cuffdif) {
#	my @old_geneExp =sort (glob "$od/old_gene/*.isoExpression.xls");
#	my @new_geneExp =sort (glob "$od/new_gene/*.isoExpression.xls");
#	open OUT,">$od/work_sh/Step6_cuffdiff.sh" || die $!;
#	for (0..$#old_geneExp) {
#		$old_geneExp[$_] =~ /.*\/(.*)\.isoExpression.xls/;
#		print OUT "cat $old_geneExp[$_] $new_geneExp[$_] >$od/$1.all_geneExpression.xls\n";
#	}
#	close OUT;
#	system "sh $od/work_sh/Step6_cuffdiff.sh";
#}

=pod
if ($step == 5 && defined $cufflinks) {
	open OUT,">$od/work_sh/Step5_cufflinks.sh" || die $!;
	print OUT "perl $Bin/bin/cufflinks_list2expression.pl $od/final_track/$index.final_tracking.list $cufflinks $index\n";
	# print OUT "perl $Bin/bin/cufflinks_list2expression.pl $od/final_track/$index.newGene_filtered_final_tracking.list $cufflinks $index.new\n";
	close OUT;

	system "sh $od/work_sh/Step5_cufflinks.sh";
	$step = 6;
}
=cut



if ($step == 6) {
    my $cmd = "perl $Bin/bin/isoExpression.pl -f $od/../Tophat_Cufflinks/Compare/ -c $cuffnorm -o $od ";
	open OUT,">$od/work_sh/Step6.sh" || die $!;
	print OUT "$cmd\n";
	close OUT;
    system $cmd;
    $step = 7;
}

if ($step == 7) {
	my @old_geneExp =sort (glob "$od/old_gene/*.isoExpression.xls");
#	my @new_geneExp =sort (glob "$od/new_gene/*.isoExpression.xls");
	open OUT,">$od/work_sh/Step7.sh" || die $!;
	for (0..$#old_geneExp) {
		$old_geneExp[$_] =~ /.*\/(.*)\.isoExpression.xls/;
		print OUT "cat $old_geneExp[$_] |grep -v ^# >$od/$1.tmp.isoExpression.xls\n";
	}
	close OUT;
	system "sh $od/work_sh/Step6.sh";
	
	## adjust field of output 
	my @tmp_exp = glob("$od/*.tmp.isoExpression.xls");
	foreach my $f (@tmp_exp) {
		my ($key) = basename($f) =~/(\w+)\.tmp\.isoExpression.xls$/;
		open (IN,"$f") or die $!;
		open (OUT,">$od/$key.isoExpression.xls") or die $!;
        print OUT "#GeneID\tLength\tFPKM\tLocus\tStrand\tCount\tNormalized\n"; # print header line
		while (<IN>) {
			chomp;
			next if (/^$/) ;

			my @tmp = split;
			print OUT join("\t",
				$tmp[0],
				$tmp[2],
				$tmp[6],
				$tmp[1],
				$tmp[3],
				$tmp[4],
				$tmp[5],
			),"\n";
		}
		close (IN) ;
		close (OUT) ;
	}

	`rm $od/*.tmp.isoExpression.xls`;
	#$step = 7;
}


######################################### subs

sub USAGE {#
	my $usage=<<"USAGE";

Usage:
	-gtf              Compare.gtf file       must be given
	-genome           reference genome      must be given
	-cuffnorm         cuffnorm out dir      must be given
	-cufflinks        cufflinks out dir     must be given
	-index            Species name          must be given
	-od               output dir            option,default ./;
	-s                step of the program   option,default 1;

USAGE
	print $usage;
	exit;
}
