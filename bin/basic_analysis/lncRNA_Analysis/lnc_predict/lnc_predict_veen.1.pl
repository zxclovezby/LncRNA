#!/usr/bin/perl -w
#
# Copyright (c) BMK 2011
# Writer:         He hua <heh@biomarker.com.cn>
# Program Date:   2011.
# Modifier:       He hua <heh@biomarker.com.cn>
# Last Modified:  2011.
use	strict;
use	Getopt::Long;
use	Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $program_name=basename($0);
my $vennDiagram	= "/share/nas2/genome/bmksoft/tool/VennDiagram/v1.1/vennDiagram.pl";

my $ver="1.0";
############################################
my %opts;
my ($cpc,$cnci,$pfam,$csf,$fa,$od);
GetOptions(
				"help|?" =>\&USAGE,
				"cpc:s"=>\$cpc,
				"cnci:s"=>\$cnci,
				"pfam:s"=>\$pfam,
				"csf:s"=>\$csf,
				"fa:s"=>\$fa,
				"od:s"=>\$od,
				) or &USAGE;
&USAGE unless ($od);

###############Time
my $BEGIN=time();
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart $program_name Time :[$Time_Start]\n\n";
###############
#print Dumper(\%trans);die;
my %lnc_ids;

if ($cpc) {
	open CPC,"$cpc"||die "$!";
	while (<CPC>) {
		chomp;
		next if (/\#/||/^$/) ;
		my $line = $_;
		my ($trans_id,$type) = (split "\t",$_)[0,2];
		$trans_id = (split ":",$trans_id)[0];
		if ($type eq 'noncoding') {
			push @{$lnc_ids{'cpc'}} , $trans_id;
		}
	}
	close CPC;
}

if ($cnci) {
	open CNCI,"$cnci"||die "$!";
	while (<CNCI>) {
		chomp;
		next if (/\#/||/^$/) ;
		my $line = $_;
		my ($trans_id,$type) = (split "\t",$_)[0,1];
		$trans_id = (split ":",$trans_id)[0];
		if ($type eq 'noncoding') {
			push @{$lnc_ids{'cnci'}} , $trans_id;
		}
	}
	close CNCI;
}


if ($pfam) {
	 my %Pfam;
	open PFAM,"$pfam"||die "$!";
	while (<PFAM>) {
		chomp;
		next if (/\#/||/^$/) ;
		my $line = $_;
		my $trans_id = (split "\t",$_)[0];
		$trans_id = (split /:/,$trans_id)[0];
		$Pfam{$trans_id}=1;
	}
	close PFAM;
	my %fasta = FaParse($fa);
	foreach my $trans_id (keys(%fasta)) {
		if (! exists $Pfam{$trans_id} ) {
			push  @{$lnc_ids{'pfam'}},$trans_id;
		}
	}
}

#print Dumper(\%lnc_ids);die;
my $temp_file = "$od/temp"; 
`mkdir $temp_file ` unless (-d $temp_file);
my @cmd;
my $j = 0;
foreach my $predict (keys(%lnc_ids)) {
	print "$predict\n";
	$j +=1 ;
	my $outfile = "$temp_file/$predict";
	open  OUT ,">$outfile" or die;
	foreach my $trans_id (@{$lnc_ids{$predict}}) {
		print OUT "$trans_id\n";
	}
	close OUT ;
	push (@cmd ,"-T$j",$outfile,"-ID$j",$predict);
}
`perl $vennDiagram @cmd  -od $od `;

`rm -r 	$temp_file ` ;
################Time
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
&Runtime($BEGIN);
print "\nEnd $program_name Time :[$Time_End]\n\n";

###############Subs
sub FaParse{
	my $fa = shift;
	my %fa;
	open IN, $fa || die;
	$/='>';
	<IN>;
	while (<IN>) {
    chomp;
    my ($id,$seq)=split /\n+/,$_,2;
	$id = (split ":",$id)[0];
    $seq=~s/\s+//g;
	$seq = ~tr/atcguUnN/ATCGTTAA/;
	$fa{$id} = $seq	;
	}
	$/='\n';
	close IN ;
	return %fa;
}
sub ABSOLUTE_DIR
{
        my ($in,$cur_dir)=@_;
        my $return="";

        if(-f $in)
        {
                my $dir=dirname($in);
                my $file=basename($in);
                chdir $dir;$dir=`pwd`;chomp $dir;
                $return="$dir/$file";
        }
        elsif(-d $in)
        {
                chdir $in;$return=`pwd`;chomp $return;
        }
        else
        {
                warn "Warning just for file and dir\n";
                exit;
        }
        chdir $cur_dir;
        return $return;
}

sub sub_format_datetime {#Time calculation subroutine
    my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
	$wday = $yday = $isdst = 0;
    sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}
sub Runtime
{ # &Runtime($BEGIN);
        my ($t1)=@_;
        my $t=time()-$t1;
        print "\nTotal elapsed time: ${t}s\n";
}
sub USAGE{
	print << "	Usage End.";
Description:The process get cds or Intro sequence from genome fasta file base on gff file.
version:$ver
Usage:
	-cpc	<STR>	CPC predictt result ;
	-cnci	<STR>	CNCI predict result ;
	-pfam	<NUM>	Pfam predict result ;
	-csf	<NUM>	phyloCSF precdict result ;
	-fa	<NUM>	lnc fsata file ;
	-od	<STR>	Out Dir;

	Usage End.
		exit;
}
