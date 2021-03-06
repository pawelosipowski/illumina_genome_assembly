package driver;

import java.io.File;
import java.util.ArrayList;

import align2.Tools;

import dna.Parser;
import fileIO.TextFile;
import fileIO.TextStreamWriter;

/**
 * @author Brian Bushnell
 * @date May 8, 2015
 *
 */
public class SummarizeSealStats {
	
	/**
	 * Code entrance from the command line.
	 * @param args Command line arguments
	 */
	public static void main(String[] args){
		
		args=Parser.parseConfig(args);
		if(Parser.parseHelp(args, true)){
			assert(false);
			System.exit(0);
		}
		
		//Create a new SummarizeSealStats instance
		SummarizeSealStats sc=new SummarizeSealStats(args);
		
		///And run it
		sc.summarize();
	}
	
	public SummarizeSealStats(String[] args){
		
		Parser parser=new Parser();
		
		ArrayList<String> names=new ArrayList<String>();
		
		/* Parse arguments */
		for(int i=0; i<args.length; i++){

			final String arg=args[i];
			String[] split=arg.split("=");
			String a=split[0].toLowerCase();
			String b=split.length>1 ? split[1] : null;
			if("null".equalsIgnoreCase(b)){b=null;}
			while(a.charAt(0)=='-' && (a.indexOf('.')<0 || i>1 || !new File(a).exists())){a=a.substring(1);}
			
			if(parser.parse(arg, a, b)){
				//do nothing
			}else if(a.equals("ignoresametaxa")){
				ignoreSameTaxa=Tools.parseBoolean(b);
			}else if(a.equals("ignoresamebarcode") || a.equals("ignoresameindex")){
				ignoreSameBarcode=Tools.parseBoolean(b);
			}else if(a.equals("ignoresamelocation") || a.equals("ignoresameloc")){
				ignoreSameLocation=Tools.parseBoolean(b);
			}else if(a.equals("usetotal") || a.equals("totaldenominator") || a.equals("totald") || a.equals("td")){
				totalDenominator=Tools.parseBoolean(b);
			}else if(!arg.contains("=")){
				String[] x=(new File(arg).exists() ? new String[] {arg} : arg.split(","));
				for(String x2 : x){names.add(x2);}
			}else{
				throw new RuntimeException("Unknown parameter "+arg);
			}
		}
		
		{//Process parser fields
			out=(parser.out1==null ? "stdout" : parser.out1);
			if(parser.in1!=null){
				String[] x=(new File(parser.in1).exists() ? new String[] {parser.in1} : parser.in1.split(","));
				for(String x2 : x){names.add(x2);}
			}
		}

		in=new ArrayList<String>();
		for(String s : names){
			Tools.getFileOrFiles(s, in, false, false, false, true);
		}
	}
	
	public void summarize(){
		TextStreamWriter tsw=new TextStreamWriter(out, true, false, false);
		tsw.start();
		tsw.print("#File\tPrimary_Name\tPrimary_Count\tOther_Count\tPrimary_Bases\tOther_Bases\tOther_ppm\n");
		for(String fname : in){
			final String s;
			if(ignoreSameTaxa || ignoreSameBarcode || ignoreSameLocation){
				s=cleanAndSummarizeFile(fname);
			}else{
				s=summarizeFile(fname);
			}
			tsw.print(s);
		}
		tsw.poisonAndWait();
	}
	
	public String summarizeFile(String fname){
		String pname=null;
		long pcount=0, ocount=0, tcount=0;
		long pbases=0, obases=0, tbases=0;
		TextFile tf=new TextFile(fname);
		for(String line=tf.nextLine(); line!=null; line=tf.nextLine()){
			if(line.startsWith("#")){
				if(line.startsWith("#Total")){
					String[] split=line.split("\t");
					tcount=Long.parseLong(split[1]);
					tbases=Long.parseLong(split[2]);
				}
			}else{
				String[] split=line.split("\t");
				long count=Long.parseLong(split[1]);
				long bases=Long.parseLong(split[3]);
				if(pcount==0 || bases>pbases || (bases==pbases && count>pcount)){
					pname=split[0];
					ocount+=pcount;
					obases+=pbases;
					pcount=count;
					pbases=bases;
				}else{
					ocount+=count;
					obases+=bases;
				}
			}
		}
		tf.close();
		double ppm;
		if(totalDenominator && tbases>0){
			ppm=obases*1000000.0/tbases;
		}else{
			ppm=(obases==0 ? 0 : obases*1000000.0/(obases+pbases));
		}
		return String.format("%s\t%s\t%d\t%d\t%d\t%d\t%.2f\n", fname, pname, pcount, ocount, pbases, obases, ppm);
	}
	
	public String cleanAndSummarizeFile(String fname){
		String pname=null;
		long pcount=0, ocount=0, tcount=0;
		long pbases=0, obases=0, tbases=0;
		TextFile tf=new TextFile(fname);
		String[] name0=null, barcode0=null;
		for(String line=tf.nextLine(); line!=null; line=tf.nextLine()){
			if(line.startsWith("#")){
				if(line.startsWith("#Total")){
					String[] split=line.split("\t");
					tcount=Long.parseLong(split[1]);
					tbases=Long.parseLong(split[2]);
				}
			}else{
				String[] split=line.split("\t");
				String[] name=split[0].toLowerCase().split(",");
				String[] barcode=name[0].split("-");
				
				long count=Long.parseLong(split[1]);
				long bases=Long.parseLong(split[3]);
				if(pcount==0 || bases>pbases || (bases==pbases && count>pcount)){
					name0=name;
					barcode0=barcode;
					pname=split[0];
					ocount+=pcount;
					obases+=pbases;
					pcount=count;
					pbases=bases;
				}else{
					boolean process=true;
					if(ignoreSameTaxa){
						if(name[2].contains(name0[2]) || name0[2].contains(name[2])){
							process=false;
						}
					}
					if(ignoreSameBarcode){
						if(barcode[0].equals(barcode0[0]) || barcode[1].equals(barcode0[1])){
							process=false;
						}
					}
					if(ignoreSameLocation){
						assert(name.length==4) : "Too many delimiters: "+name.length+"\n"+line+"\n";
						if(name[3].equals(name0[3])){
							process=false;
						}
					}
					if(process){
						ocount+=count;
						obases+=bases;
					}
				}
			}
		}
		tf.close();
		double ppm;
		if(totalDenominator && tbases>0){
			ppm=obases*1000000.0/tbases;
		}else{
			ppm=(obases==0 ? 0 : obases*1000000.0/(obases+pbases));
		}
		return String.format("%s\t%s\t%d\t%d\t%d\t%d\t%.2f\n", fname, pname, pcount, ocount, pbases, obases, ppm);
	}
	
	final ArrayList<String> in;
	final String out;
	boolean ignoreSameTaxa=false;
	boolean ignoreSameBarcode=false;
	boolean ignoreSameLocation=false;
	boolean totalDenominator=false;
	
}
