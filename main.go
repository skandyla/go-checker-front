package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gorilla/mux"
	"github.com/namsral/flag"
)

var (
	proxyUrl string
)


func ResponseProxyUrl(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	proxyAddr := fmt.Sprintf("%s/%s", proxyUrl, vars["key"])

	w.Header().Add("Content-Type", "text/plain")
	hostname, err := os.Hostname()
	if err != nil {
		log.Fatalln(err)
	}
	// Get Response
	startRes := time.Now()
	resp, err := http.Get(proxyAddr)
	if err != nil {
		// handle err
		log.Fatalln(err)
	}
	defer resp.Body.Close()

	fmt.Println(proxyAddr)
	endRes := time.Now()
	//fmt.Println("Response took", endRes.Sub(startRes))
	bodyString := ""
	if resp.StatusCode == http.StatusOK {
		bodyBytes, err := ioutil.ReadAll(resp.Body)
		bodyString = string(bodyBytes)
		if err != nil {
			fmt.Println(resp.StatusCode)
			log.Fatalln(err)
		}
		//print bodyString to stdout
		//fmt.Println(bodyString)

		//return to http
		fmt.Fprintf(w, "URL: %s, Response took: %s Code: %s, Hostname: %s,\nBody: %s", proxyAddr, endRes.Sub(startRes), strconv.Itoa(resp.StatusCode), hostname, bodyString)

	} else {
		//fmt.Println("stdout errors:", errs)
		w.WriteHeader(401)
		//prints to http client
		fmt.Fprintf(w, "Status code from %s: %s, hostname:", proxyAddr, strconv.Itoa(resp.StatusCode), hostname)
	}
}

func main() {
	flag.StringVar(&proxyUrl, "proxy-url", "http://go-cassandra-checker.testing", "proxy url address")
	flag.Parse()

	r := mux.NewRouter()
	r.HandleFunc("/info", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "gangnam style")
	})

	r.HandleFunc("/proxy/{key}", ResponseProxyUrl)
	http.Handle("/", r)

	// Start the server
	addr := ":8080"
	log.Println("listen on", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
