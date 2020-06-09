import swan_vis as swan

ab_file = 'all_talon_abundance_filtered.tsv'
ref_gtf = '/Users/fairliereese/mortazavi_lab/ref/gencode.v29/gencode.v29.annotation.gtf'
hep_1_gtf = 'hepg2_1_talon.gtf'
hep_2_gtf = 'hepg2_2_talon.gtf'
hff_1_gtf = 'hffc6_1_talon.gtf'
hff_2_gtf = 'hffc6_2_talon.gtf'
hff_3_gtf = 'hffc6_3_talon.gtf'

# adding data to the swangraph
sg = swan.SwanGraph()
sg.add_annotation(ref_gtf)
sg.add_dataset('HepG2_1', hep_1_gtf,
	counts_file=ab_file,
	count_cols='hepg2_1')
sg.add_dataset('HepG2_2', hep_2_gtf,
	counts_file=ab_file,
	count_cols='hepg2_2')
sg.add_dataset('HFFc6_1', hff_1_gtf,
	counts_file=ab_file,
	count_cols='hffc6_1')
sg.add_dataset('HFFc6_2', hff_2_gtf,
	counts_file=ab_file,
	count_cols='hffc6_2')
sg.add_dataset('HFFc6_3', hff_3_gtf,
	counts_file=ab_file,
	count_cols='hffc6_3')
sg.save_graph('swan')
sg = swan.SwanGraph('swan.p')


# de gene and transcript tests
dataset_groups=[['HepG2_1', 'HepG2_2'], ['HFFc6_1', 'HFFc6_2', 'HFFc6_3']]
sg.de_gene_test(dataset_groups)
sg.de_transcript_test(dataset_groups)
de_gids, _ = sg.get_de_genes()
print('Found {} differentially expressed genes'.format(len(de_gids)))
de_tids, _ = sg.get_de_transcripts()
print('Found {} differentially expressed transcripts'.format(len(de_tids)))
is_gids, _ = sg.find_isoform_switching_genes()
print('Found {} isoform switching genes'.format(len(is_gids)))
sg.save_graph('swan')


# es and ir detection
es_gids = sg.find_es_genes()
print('Found {} novel exon-skipping genes'.format(len(es_gids)))
ir_gids = sg.find_ir_genes()
print('Found {} novel intron-retaining genes'.format(len(ir_gids)))

# find and plot genes with es or ir and isoform switching
ir_es_gids = list(set(ir_gids+es_gids))
cool_gids = list(set(is_gids)&set(ir_es_gids))

# and the ADRM1 gene report
sg.gen_report('ADRM1', 'figures/adrm1_paper', heatmap=True, novelty=True, include_qvals=True, indicate_novel=True)
