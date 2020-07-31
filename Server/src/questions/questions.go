package questions

import (
	"bufio"
	"encoding/csv"
	"io"
	"log"
	"os"
)

// QuestionObj ...
type QuestionObj struct {
	ID       int    `json:"id"`
	Question string `json:"question"`
	Answer   string `json:"answer"`
}

// TFObj 是非題
type TFObj struct {
	Domain     string `json:"domain"`
	Difficulty string `json:"difficulty"`
	Question   string `json:"question"`
	Answer     bool   `json:"answer"`
}

// ReadQuestionsFromCSV ...
func ReadQuestionsFromCSV() []TFObj {
	csvFile, _ := os.Open("QuestionList.csv")
	reader := csv.NewReader(bufio.NewReader(csvFile))
	var questions []TFObj
	for {
		line, error := reader.Read()
		if error == io.EOF {
			break
		} else if error != nil {
			log.Fatal(error)
		}
		// 只讀取是非題
		// qid, _ := strconv.Atoi(line[0])
		if line[2] != "TF" {
			continue
		}
		questions = append(questions, TFObj{
			Domain:     line[0],
			Difficulty: line[1],
			Question:   line[3],
			Answer:     line[4] == "O"})
	}
	return questions
}
