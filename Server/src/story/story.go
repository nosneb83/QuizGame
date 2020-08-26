package story

import (
	"bufio"
	"encoding/csv"
	"io"
	"log"
	"os"
)

// File 劇情csv檔
var File [][]string

// ReadStoryFromCSV 讀取劇情csv檔
func ReadStoryFromCSV() {
	csvFile, _ := os.Open("Story.csv")
	reader := csv.NewReader(bufio.NewReader(csvFile))
	for {
		// 讀檔
		line, error := reader.Read()
		if error == io.EOF {
			break
		} else if error != nil {
			log.Fatal(error)
		}
		// 添加
		File = append(File, line)
	}
}
