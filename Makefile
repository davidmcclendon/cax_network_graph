all: graphdata.json

make_json: build/clean_data.csv R/1_make_data.R
	Rscript R/1_make_data.R

graphdata.json: make_json
	echo '{"nodes": [' > build/graphdata.json
	cat build/provider-nodes-data.json | sed 's/]//g' | sed 's/\[//g' >> build/graphdata.json
	echo "," >> build/graphdata.json
	cat build/service-nodes-data.json | sed 's/]//g' | sed 's/\[//g' >> build/graphdata.json
	echo '],' >> build/graphdata.json
	echo '"links": [' >> build/graphdata.json
	cat build/connections-data.json | sed 's/]//g' | sed 's/\[//g' >> build/graphdata.json
	echo ']}' >> build/graphdata.json

build/clean_data.csv: build/ R/0_cax_data_clean.R
	Rscript R/0_cax_data_clean.R

build/:
	rm -rf build
	mkdir build

clean:
	rm -rf build