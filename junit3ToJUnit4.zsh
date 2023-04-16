#!/bin/zsh

# Script to convert JUnit3 code into JUnit4 code.
#
# What this code does *not* do is deal with calls to
# junit.framework.TestSuite.addTestSuite(clazz);
#

for ii in src/**/*Test(|Base|Case|Suite|Unit|Registry|NoManager|WithManager|Plugin).java; do
    echo ${ii}

    if [[ `grep -m 1 -c "extends *TestCase" ${ii}` -eq 1 ]]; then
        # 'extends TestCase' is problematic because the class (and its sub-classes)
        # may call methods now inside 'Assert.*'. Replacing these calls is error
        # prone as one may have locally defined methods starting with "assert".

        # Assertions are imported statically
        sed -i -e "s/[ \t]\+extends *TestCase//" $ii

        # But now there is no super.(tearDown|setUp)
        sed -i -r -e "N; s/[ \t]*super\.setUp\(\);//" $ii
        sed -i -r -e "N; s/[ \t]*super\.tearDown\(\);//" $ii

        # nor is there a constructor taking a String argument
        sed -i -r -e "N; s/[ \t]*super\([[:alpha:]]*\);//" $ii

#        sed -i -r -e "N; s/[ \t]*super\.setUp\(\);//" -i -e "N; s/[ \t]*super\.tearDown..;//" $ii
        sed -i -r ':a;N;$!ba;s/[ \t]*@Override\n[ \t]*(protected|public) void setUp/  protected void setUp/g' $ii
        sed -i -r ':a;N;$!ba;s/[ \t]*@Override\n[ \t]*(protected|public) void tearDown/  protected void tearDown/g' $ii

        if [[ `grep -E -m 1 -c "import (junit.framework|org.junit).Assert;" $ii` -eq 0 ]]; then
            sed -i -e "s/import[ \t]\+junit.framework.TestCase;/import org.junit.Assert;/" $ii
        else
            sed -i -e "s/import junit.framework.TestCase;//" $ii
        fi
    fi

    sed -i -e "s/import junit.framework.TestSuite;/\/\/ FIXME include in TestSuite @RunWith(Suite.class)@Suite.SuiteClasses(...)/" -e "s/public[ \t]\+static[ \t]\+TestSuite[ \t]suite\(\)/public static Object suite() \/\/ FIXME TestSuite/" $ii

    ### static setUp and tearDown methods and @BeforeClass/@AfterClass annotations
    sed -i -r ':a;N;$!ba;s/[ \t]*(protected|public) (final )?void test_setUp/  @BeforeClass\n  protected static void setUpClass/g' $ii
    sed -i -r ':a;N;$!ba;s/[ \t]*(protected|public) (final )?void test_tearDown/  @AfterClass\n  protected static void tearDownClass/g' $ii

    ### Annotate @Test/@Before/@After only if they are not present in the class already.

    if [[ `grep -m 1 -c "@Test" ${ii}` -eq 0 ]]; then
        sed -i -e "s/^[ \t]*public[ \t]\+void[ \t]\+test/  @Test\n&/" $ii
    fi

    if [[ `grep -m 1 -c "@Before" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^[ \t]*(protected|public)[ \t]+void[ \t]+setUp\(\)/  @Before\n  public void setUp()/" $ii
    fi
    if [[ `grep -m 1 -c "@After" ${ii}` -eq 0 ]]; then
        sed -i -r -e "s/^[ \t]*(protected|public)[ \t]+void[ \t]+tearDown\(\)/  @After\n  public void tearDown()/" $ii
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

    # Manage assertions
    if [[ `grep -m 1 -c "assertEquals" $ii` -eq 1 && `grep -m 1 -c "import static org.junit.Assert.assertEquals;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport static org.junit.Assert.assertEquals;/1" $ii
    fi

    if [[ `grep -m 1 -c "assertNotNull" $ii` -eq 1 && `grep -m 1 -c "import static org.junit.Assert.assertNotNull;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport static org.junit.Assert.assertNotNull;/1" $ii
    fi

    if [[ `grep -m 1 -c "assertNull" $ii` -eq 1 && `grep -m 1 -c "import static org.junit.Assert.assertNull;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport static org.junit.Assert.assertNull;/1" $ii
    fi

    if [[ `grep -m 1 -c "assertFalse" $ii` -eq 1 && `grep -m 1 -c "import static org.junit.Assert.assertFalse;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport static org.junit.Assert.assertFalse;/1" $ii
    fi

    if [[ `grep -m 1 -c "assertTrue" $ii` -eq 1 && `grep -m 1 -c "import static org.junit.Assert.assertTrue;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport static org.junit.Assert.assertTrue;/1" $ii
    fi

    if [[ `grep -m 1 -c "assertSame" $ii` -eq 1 && `grep -m 1 -c "import static org.junit.Assert.assertSame;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport static org.junit.Assert.assertSame;/1" $ii
    fi

    if [[ `grep -m 1 -c "assertNotSame" $ii` -eq 1 && `grep -m 1 -c "import static org.junit.Assert.assertNotSame;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport static org.junit.Assert.assertNotSame;/1" $ii
    fi

    if [[ `grep -m 1 -c "fail(.*)" $ii` -eq 1 && `grep -m 1 -c "import static org.junit.Assert.fail;" $ii` -eq 0 ]]; then
        sed -i "0,/package .*;/ s/package .*;/&\nimport static org.junit.Assert.fail;/1" $ii
    fi
done
