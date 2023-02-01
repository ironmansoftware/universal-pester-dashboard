Describe "Pester Tests" {
    Context "PowerShell Universal" {
        It "should pass" {
            1 | Should -be 1 
        }
        It "should pass 2" {
            1 | Should -be 1 
        }
        It "should pass 3" {
            1 | Should -be 1 
        }
        It "should pass 4" {
            1 | Should -be 1 
        }
        It "should fail" {
            1 | Should -be 2
        }
    }
}