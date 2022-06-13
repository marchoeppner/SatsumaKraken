#!/usr/bin/env nextflow

/**
===============================
Satsuma Pipeline
===============================

This pipeline aligns a query genome against a target to produce an alignment chain file. 

### Homepage / git
https://github.com/marchoeppner/SatsumaKraken

### Implementation
Q4 2020

Author: Marc P. Hoeppner, m.hoeppner@ikmb.uni-kiel.de

**/

// Pipeline version

params.version = workflow.manifest.version

// Help message
helpMessage = """
===============================================================================
Satsuma alignment pipeline | version ${params.version}
===============================================================================
Usage: nextflow run marchoeppner/SatsumaKraken --query genome_1.fa --target genome_2.fa

Required parameters:
--query                      A query genome in fasta format. This genome will be in column 1 of the chain file
--target                     A target genome in fasta format. This genome will in column 4 of the chain file
Output:
--outdir                     Local directory to which all output is written (default: results)
"""

params.help = false

// Show help when needed
if (params.help){
    log.info helpMessage
    exit 0
}

query_fasta = Channel.fromPath(file(params.query))
	.ifEmpty { exit 1, "Missing a query file!" }

target_fasta = Channel.fromPath(file(params.target))
	.ifEmpty { exit , "Missing target fille" }

// split the query into chunks
process fastaSplitSize {

        input:
        file(fasta) from query_fasta
        
        output:
        file("*.part-*.*") into query_chunks

        script:

        """
                fasta-splitter.pl -part-sequence-size 200000000 $fasta
        """
}

// align each chunk to the target
process align_genomes {

	// publishDir "${params.outdir}/${ref_name}/satsuma_chunks", mode: 'copy'
        label 'satsuma'

        input:
        file(ref_genome) from target_fasta.collect()
	file(query_chunk) from query_chunks.flatMap()

        output:
	file(satsuma_chain_chunk) into SatsumaChunk

        script:

        query_c = query_chunk.getBaseName()
        satsuma_chain_chunk = "satsuma_summary.chained.out_" + query_c

        """
                SatsumaSynteny2 -q $query_chunk -t $ref_genome -threads ${task.cpus} -o align 2>&1 >/dev/null
                cp align/satsuma_summary.chained.out $satsuma_chain_chunk
        """
}

process merge_satsuma_chunks {

	publishDir "${params.outdir}/", mode: 'copy'

	input:
	file(satsuma_chunk) from SatsumaChunk.collect()

	output:
	file(chain)

	script:

	chain = "satsuma_summary.chained.out"

	"""
		cat $satsuma_chunk > $chain
	"""

}
