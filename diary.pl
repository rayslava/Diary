#!/usr/bin/perl

use utf8;
use strict;
use File::stat;

my $version = "0.1";
my $filename = "diary";
my $author = "ray";
my $editor = "/usr/bin/vim";
my $notedir = "/home/ray/Documents/private/diary/notes/";

my $template_head = '
\documentclass[12pt]{letter}
\usepackage[utf8]{inputenc}
\usepackage[russian]{babel}
\usepackage{indentfirst}
\usepackage{fancyhdr}
\begin{document}
';

my $help = '		Command line keys:
		-n or --newnote 	: Generate new note
		-g or --generate 	: Produce a pdf file
		-h or --help 		: print this help
';

my $template_tail = '
\end{document}';

sub today_note {
	opendir my($dir),$notedir or die "Can't open dir with notes";
	foreach my $filename (readdir($dir)) {
		next if !($filename =~ /\.tex/);
		my ($fsec,$fmin,$fhour,$fmday,$fmon,$fyear,$fwday,$fyday,$fisdst) = localtime (stat("$notedir/$filename")->mtime);
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		return $filename if ($fmday == $mday && $fmon == $mon && $fyear == $year);
	};
	closedir $dir;
	return 0;
};

sub generate_tex {
       	open(my $tmptexfile, ">/tmp/" . $filename . ".tex");
	print $tmptexfile $template_head;
	opendir my($dir),$notedir or die "Can't open dir with notes";
	my @files = sort readdir($dir);
	foreach my $notefile (@files) {
		open NOTE, "<$notedir/$notefile";
		print $tmptexfile <NOTE>;
		close NOTE;
	};
	print $tmptexfile $template_tail;
	close($tmptexfile);
	closedir $dir;
	produce_pdf();
};

# Generating new note
sub generate_note {
	if (my $today_note = today_note())
	{
		open my $newnote, ">>$notedir/$today_note";
		print $newnote "\\vspace{12mm}\n\\begin{flushright}\\hline\n";
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		print ($newnote "Добавление в $hour:$min\n\\end{flushright}\n\n");
		system ("$editor $notedir/$today_note");
		return;
	};
	my $timestamp = time();
	my $newnotename = "$notedir/$timestamp.tex";
	open my $newnote, ">$newnotename";
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year -= 100;
	$mon += 1;
	print $newnote "\\newpage\n";
	print $newnote "\\pagestyle{empty}\n";
	print $newnote "\\pagestyle{fancy}\n";
	print $newnote "\\lhead{$author}\n";
	printf $newnote "\\chead{--- %02d.%02d.%02d ---}\n", $mday,$mon,$year;
	print $newnote "\\rhead{дневник}\n";
	print $newnote "\\cfoot{--- ~\\arabic{page}~ ---}\n";
	printf $newnote "\\rfoot{в %02d:%02d}\n",$hour,$min;
	close $newnote;
	system("$editor $newnotename");
}

sub produce_pdf {
	system('pdflatex --interaction=nonstopmode /tmp/diary.tex');
	system('rm *.aux *.log');
}

# Command line
foreach (@ARGV){
	generate_note() if (/-n/ or /--newnote/);
	generate_tex() if (/-g/ or /--generate/);
	print $help if /-h/;
}

