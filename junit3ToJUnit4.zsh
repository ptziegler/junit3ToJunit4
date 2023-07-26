#!/bin/zsh

# Script to convert JUnit3 code into JUnit4 code.
#
# What this code does *not* do is deal with calls to
# junit.framework.TestSuite.addTestSuite(clazz);
#

for ii in src/**/*Test(|Base|Case|Suite|Unit|Registry|NoManager|WithManager|Plugin).java; do
    echo ${ii}

    if [[ `grep -m 1 -c "extends *TestCase" ${ii}` -eq 1 ]]; then
        ###################
        #  JUnit3 to JUnit4
    
        # 'extends TestCase' is problematic because the class (and its sub-classes)
        # may call methods now inside 'Assert.*'. Replacing these calls is error
        # prone as one may have locally defined methods starting with "assert".

        sed -i -e "s/[ \t]\+extends *TestCase/ extends Assert/" $ii
        
        if [[ `grep -m 1 -c "extends Assert" $ii` -eq 1 && `grep -m 1 -c "import org.junit.Assert;" $ii` -eq 0 ]]; then
            sed -i "0,/package .*;/ s/package .*;/&\n\nimport org.junit.Assert;/1" $ii
        fi

        # But now there is no super.(tearDown|setUp)
        sed -i -r -e "N; s/[ \t]*super\.setUp\(\);//" $ii
        sed -i -r -e "N; s/[ \t]*super\.tearDown\(\);//" $ii

        # nor is there a constructor taking a String argument
        sed -i -r -e "N; s/[ \t]*super\([[:alpha:]]*\);//" $ii

#        sed -i -r -e "N; s/[ \t]*super\.setUp\(\);//" -i -e "N; s/[ \t]*super\.tearDown..;//" $ii
        sed -i -r ':a;N;$!ba;s/[ \t]*(@Override\n[ \t]*)?(protected|public) void setUp/\tprotected void setUp/g' $ii
        sed -i -r ':a;N;$!ba;s/[ \t]*(@Override\n[ \t]*)?(protected|public) void tearDown/\tprotected void tearDown/g' $ii
        
        ###################
        #  JUnit4 to JUnit5
        
        sed -i -e "s/[ \t]\+extends Assert/ extends Assertions/" $ii
        
        if [[ `grep -m 1 -c "extends Assertions" $ii` -eq 1 && `grep -m 1 -c "import org.junit.jupiter.api.Assertions;" $ii` -eq 0 ]]; then
            sed -i -e "s/import org.junit.Assert;/import org.junit.jupiter.api.Assertions;/" $ii
        fi
    fi

    ###################
    #  JUnit3 to JUnit4
    
    # Disabled test cases either start with DISABLE_ or DISABLED_. This prefix
    # should be removed and be replaced by the @Ignore annotation
    
    sed -i -r ':a;N;$!ba;s/[ \t]*(protected|public) void DISABLE_test/\t@Ignore\n\tpublic void test/g' $ii
    sed -i -r ':a;N;$!ba;s/[ \t]*(protected|public) void DISABLED_test/\t@Ignore\n\tpublic void test/g' $ii

    # Rename test_setUp and test_tearDown because they're not test cases
    sed -i -r ':a;N;$!ba;s/[ \t]*(protected|public) (final )?void test_setUp/\tprotected static void setUpClass/g' $ii
    sed -i -r ':a;N;$!ba;s/[ \t]*(protected|public) (final )?void test_tearDown/\tprotected static void tearDownClass/g' $ii

    ### Annotate @BeforeClass/@AfterClass/@Test/@Before/@After only if they are not present in the class already.

    if [[ `grep -m 1 -c "@Test" ${ii}` -eq 0 ]]; then
        sed -i -e "s/^[ \t]*public[ \t]\+void[ \t]\+test/\t@Test\n&/" $ii
    fi

    if [[ `grep -m 1 -c "@Before" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^[ \t]*(protected|public)[ \t]+void[ \t]+setUp\(\)/\t@Before\n\tpublic void setUp()/" $ii
    fi
    if [[ `grep -m 1 -c "@After" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^[ \t]*(protected|public)[ \t]+void[ \t]+tearDown\(\)/\t@After\n\tpublic void tearDown()/" $ii
    fi

    if [[ `grep -m 1 -c "@BeforeClass" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^[ \t]*protected static void setUpClass\(\)/\t@BeforeClass\n\tprotected static void setUpClass()/" $ii
    fi

    if [[ `grep -m 1 -c "@AfterClass" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^[ \t]*protected static void tearDownClass\(\)/\t@AfterClass\n\tprotected static void tearDownClass()/" $ii
    fi

    # Fix AssertionFailedError exception handling --> java.lang.AssertionError
    sed -i -e "s/import[ \t]\+junit.framework.AssertionFailedError;//" \
        -e "s/\(junit\.framework\.\)\?AssertionFailedError/AssertionError/g" $ii

    ### Fix the any imports left to the new package name
    sed -i -e "s/import junit.framework./import org.junit./" $ii

    # Should you need to remove duplicates...
    # sed -i ':a;N;$!ba;s/[ \t]*@Test\n[ \t]*@Test/  @Test/g' $ii
    # sed -i ':a;N;$!ba;s/[ \t]*@Before\n*[ \t]*@Before/  @Before/g' $ii
    # sed -i ':a;N;$!ba;s/[ \t]*@After\n[ \t]*@After/  @After/g' $ii

    if [[ `grep -m 1 -c "@BeforeClass" $ii` -eq 1 && `grep -m 1 -c "import org.junit.BeforeClass;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\n\nimport org.junit.BeforeClass;/1" $ii
    fi

    if [[ `grep -m 1 -c "@AfterClass" $ii` -eq 1 && `grep -m 1 -c "import org.junit.AfterClass;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\n\nimport org.junit.AfterClass;/1" $ii
    fi

    if [[ `grep -m 1 -c "@Test" $ii` -eq 1 && `grep -m 1 -c "import org.junit.Test;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\n\nimport org.junit.Test;/1" $ii
    fi

    if [[ `grep -m 1 -c "@After" $ii` -eq 1 && `grep -m 1 -c "import org.junit.After;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport org.junit.After;/1" $ii
    fi

    if [[ `grep -m 1 -c "@Before" $ii` -eq 1 && `grep -m 1 -c "import org.junit.Before;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport org.junit.Before;/1" $ii
    fi

    if [[ `grep -m 1 -c "@Ignore" $ii` -eq 1 && `grep -m 1 -c "import org.junit.Ignore;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport org.junit.Ignore;/1" $ii
    fi

    ###################
    #  JUnit4 to JUnit5

    sed -i -r -e "s/^import org.junit.Test;/import org.junit.jupiter.api.Test;/" $ii

    if [[ `grep -m 1 -c "@BeforeEach" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^\t@Before$/\t@BeforeEach/" $ii
        sed -i -r -e "s/^import org.junit.Before;/import org.junit.jupiter.api.BeforeEach;/" $ii
    fi

    if [[ `grep -m 1 -c "@AfterEach" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^\t@After$/\t@AfterEach/" $ii
        sed -i -r -e "s/^import org.junit.After;/import org.junit.jupiter.api.AfterEach;/" $ii
    fi

    if [[ `grep -m 1 -c "@BeforeAll" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^\t@BeforeClass/\t@BeforeAll/" $ii
        sed -i -r -e "s/^\t@BeforeClass/\t@BeforeAll/" $ii
        sed -i -r -e "s/^\tprotected static void setUpClass/\tprotected static void setUpAll/" $ii
    fi

    if [[ `grep -m 1 -c "@AfterAll" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^\t@AfterClass/\t@AfterAll/" $ii
        sed -i -r -e "s/^\t@BeforeClass/\t@BeforeAll/" $ii
        sed -i -r -e "s/^\tprotected static void tearDownClass/\tprotected static void tearDownAll/" $ii
    fi

    if [[ `grep -m 1 -c "@Ignore" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^\t@Ignore/\t@Disabled/" $ii
        sed -i -r -e "s/^import org.junit.Ignore;/import org.junit.jupiter.api.Disabled;/" $ii
    fi
done

for ii in src/**/*Tests.java; do
    echo ${ii}

    ###########################################################
    #  "Convert" the JUnit3 Test Suites into JUnit4 Test Suites

    if [[ `grep -m 1 -c "public static Test suite()" ${ii}` -eq 1 ]]; then
        sed -i -r -e "s/^[ \t]*public class (\w+) (extends .*)?/  @RunWith(Suite.class)\n@SuiteClasses({\n    \/\/ FIXME include in TestSuite\n})\npublic class \1/" $ii
        
        if [[ `grep -m 1 -c "@RunWith(Suite.class)" $ii` -eq 1 && `grep -m 1 -c "import org.junit.RunWith;" $ii` -eq 0 ]]; then
            sed -i "0,/package .*;/ s/package .*;/&\n\nimport org.junit.RunWith;/1" $ii
        fi
        
        if [[ `grep -m 1 -c "@RunWith(Suite.class)" $ii` -eq 1 && `grep -m 1 -c "import org.junit.Suite;" $ii` -eq 0 ]]; then
            sed -i "0,/package .*;/ s/package .*;/&\n\nimport org.junit.Suite;/1" $ii
        fi
        
        if [[ `grep -m 1 -c "@SuiteClass" $ii` -eq 1 && `grep -m 1 -c "import org.junit.Suite.SuiteClass;" $ii` -eq 0 ]]; then
            sed -i "0,/package .*;/ s/package .*;/&\n\nimport org.junit.Suite.SuiteClass;/1" $ii
        fi
    fi
    
    #########################################################
    #  Convert the JUnit4 Test Suites into JUnit5 Test Suites

    sed -i -r -e "s/^[ \t]*@RunWith\(Suite\.class\)/@Suite/" $ii
    sed -i -r -e "s/^[ \t]*@SuiteClasses\(\{/@SelectClasses\(\{/" $ii

    if [[ `grep -m 1 -c "@SelectClasses" $ii` -eq 1 && `grep -m 1 -c "import org.junit.platform.suite.api.SelectClasses;" $ii` -eq 0 ]]; then
        sed -i -r -e "s/^import org.junit.runners.Suite.SuiteClasses;/import org.junit.platform.suite.api.SelectClasses;/" $ii
    fi

    if [[ `grep -m 1 -c "@Suite" $ii` -eq 1 && `grep -m 1 -c "import org.junit.platform.suite.api.Suite;" $ii` -eq 0 ]]; then
        sed -i -r -e "s/^import org.junit.runners.Suite;/import org.junit.platform.suite.api.Suite;/" $ii
    fi
done
